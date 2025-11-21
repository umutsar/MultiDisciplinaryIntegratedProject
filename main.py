# import the necessary packages
import numpy as np
import argparse
import time
import cv2
import os
import glob

from sort import *
tracker = Sort()
memory = {}
line = [(43, 543), (550, 655)]
counter = 0

# construct the argument parse and parse the arguments
ap = argparse.ArgumentParser()
ap.add_argument("-i", "--input", type=str, default=None,
	help="input source: camera index (e.g., 0, 1) or path to video file (e.g., video.mp4). Default: 0 (camera)")
ap.add_argument("-o", "--output", type=str, default=None,
	help="optional path to output video (if not provided, no video will be saved)")
ap.add_argument("-y", "--yolo", type=str, default="yolo-coco",
	help="base path to YOLO directory (default: yolo-coco)")
ap.add_argument("--confidence", type=float, default=0.5,
	help="minimum probability to filter weak detections")
ap.add_argument("--threshold", type=float, default=0.3,
	help="threshold when applying non-maxima suppression")
ap.add_argument("--save-frames", action="store_true",
	help="save individual frames to output directory")
args = vars(ap.parse_args())

# Create output directory if saving frames
if args["save_frames"]:
	os.makedirs("output", exist_ok=True)
	files = glob.glob('output/*.png')
	for f in files:
		os.remove(f)

# Return true if line segments AB and CD intersect
def intersect(A,B,C,D):
	return ccw(A,C,D) != ccw(B,C,D) and ccw(A,B,C) != ccw(A,B,D)

def ccw(A,B,C):
	return (C[1]-A[1]) * (B[0]-A[0]) > (B[1]-A[1]) * (C[0]-A[0])

# load the COCO class labels our YOLO model was trained on
labelsPath = os.path.sep.join([args["yolo"], "coco.names"])
LABELS = open(labelsPath).read().strip().split("\n")

# initialize a list of colors to represent each possible class label
np.random.seed(42)
COLORS = np.random.randint(0, 255, size=(200, 3),
	dtype="uint8")

# derive the paths to the YOLO weights and model configuration
weightsPath = os.path.sep.join([args["yolo"], "yolov3.weights"])
configPath = os.path.sep.join([args["yolo"], "yolov3.cfg"])

# load our YOLO object detector trained on COCO dataset (80 classes)
# and determine only the *output* layer names that we need from YOLO
print("[INFO] loading YOLO from disk...")
net = cv2.dnn.readNetFromDarknet(configPath, weightsPath)
# YENİ VE UYUMLU KOD
ln = net.getLayerNames()
# getUnconnectedOutLayers() hem eski ([[12], [26]]) hem de yeni (array([12, 26])) formatları döndürebilir.
# Bu yüzden çıktıyı tek boyutlu bir diziye dönüştürerek her iki durumda da çalışmasını sağlıyoruz.
output_layers_indices = net.getUnconnectedOutLayers().flatten()
ln = [ln[i - 1] for i in output_layers_indices]

# Determine input source (camera or video file)
input_source = args["input"]
is_camera = False

# If no input specified, default to camera 0
if input_source is None:
	input_source = 0
	is_camera = True
else:
	# Check if input is a number (camera index) or a file path
	try:
		input_source = int(input_source)
		is_camera = True
	except ValueError:
		# It's a file path
		is_camera = False
		if not os.path.exists(input_source):
			print("[ERROR] Video file not found: {}".format(input_source))
			exit(1)

# Initialize the video stream
if is_camera:
	print("[INFO] starting video stream from camera {}...".format(input_source))
	vs = cv2.VideoCapture(input_source)
	
	# Check if camera opened successfully
	if not vs.isOpened():
		print("[ERROR] Could not open camera {}. Please check if camera is connected.".format(input_source))
		exit(1)
	
	# Set camera properties for better performance
	vs.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
	vs.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
	vs.set(cv2.CAP_PROP_FPS, 30)
	
	print("[INFO] Camera opened successfully. Press 'q' to quit.")
else:
	print("[INFO] opening video file: {}...".format(input_source))
	vs = cv2.VideoCapture(input_source)
	
	# Check if video opened successfully
	if not vs.isOpened():
		print("[ERROR] Could not open video file: {}".format(input_source))
		exit(1)
	
	# Try to determine the total number of frames in the video file
	try:
		prop = cv2.CAP_PROP_FRAME_COUNT
		total = int(vs.get(prop))
		print("[INFO] {} total frames in video".format(total))
	except:
		print("[INFO] could not determine # of frames in video")
		total = -1

writer = None
(W, H) = (None, None)
frameIndex = 0
fps_start_time = time.time()
fps_frame_count = 0
fps = 0
total = -1  # Initialize total for camera mode

# loop over frames from the video file stream
while True:
	# read the next frame from the file
	(grabbed, frame) = vs.read()

	# if the frame was not grabbed, then we have reached the end
	# of the stream
	if not grabbed:
		break

	# if the frame dimensions are empty, grab them
	if W is None or H is None:
		(H, W) = frame.shape[:2]

	# construct a blob from the input frame and then perform a forward
	# pass of the YOLO object detector, giving us our bounding boxes
	# and associated probabilities
	blob = cv2.dnn.blobFromImage(frame, 1 / 255.0, (416, 416),
		swapRB=True, crop=False)
	net.setInput(blob)
	start = time.time()
	layerOutputs = net.forward(ln)
	end = time.time()

	# initialize our lists of detected bounding boxes, confidences,
	# and class IDs, respectively
	boxes = []
	confidences = []
	classIDs = []

	# loop over each of the layer outputs
	for output in layerOutputs:
		# loop over each of the detections
		for detection in output:
			# extract the class ID and confidence (i.e., probability)
			# of the current object detection
			scores = detection[5:]
			classID = np.argmax(scores)
			confidence = scores[classID]

			# filter out weak predictions by ensuring the detected
			# probability is greater than the minimum probability
			if confidence > args["confidence"]:
				# scale the bounding box coordinates back relative to
				# the size of the image, keeping in mind that YOLO
				# actually returns the center (x, y)-coordinates of
				# the bounding box followed by the boxes' width and
				# height
				box = detection[0:4] * np.array([W, H, W, H])
				(centerX, centerY, width, height) = box.astype("int")

				# use the center (x, y)-coordinates to derive the top
				# and and left corner of the bounding box
				x = int(centerX - (width / 2))
				y = int(centerY - (height / 2))

				# update our list of bounding box coordinates,
				# confidences, and class IDs
				boxes.append([x, y, int(width), int(height)])
				confidences.append(float(confidence))
				classIDs.append(classID)

	# apply non-maxima suppression to suppress weak, overlapping
	# bounding boxes
	idxs = cv2.dnn.NMSBoxes(boxes, confidences, args["confidence"], args["threshold"])
	
	dets = []
	if len(idxs) > 0:
		# loop over the indexes we are keeping
		for i in idxs.flatten():
			(x, y) = (boxes[i][0], boxes[i][1])
			(w, h) = (boxes[i][2], boxes[i][3])
			dets.append([x, y, x+w, y+h, confidences[i]])

	np.set_printoptions(formatter={'float': lambda x: "{0:0.3f}".format(x)})
	dets = np.asarray(dets)
	tracks = tracker.update(dets)

	boxes = []
	indexIDs = []
	c = []
	previous = memory.copy()
	memory = {}

	for track in tracks:
		boxes.append([track[0], track[1], track[2], track[3]])
		indexIDs.append(int(track[4]))
		memory[indexIDs[-1]] = boxes[-1]

	if len(boxes) > 0:
		i = int(0)
		for box in boxes:
			# extract the bounding box coordinates
			(x, y) = (int(box[0]), int(box[1]))
			(w, h) = (int(box[2]), int(box[3]))

			# draw a bounding box rectangle and label on the image
			# color = [int(c) for c in COLORS[classIDs[i]]]
			# cv2.rectangle(frame, (x, y), (x + w, y + h), color, 2)

			color = [int(c) for c in COLORS[indexIDs[i] % len(COLORS)]]
			cv2.rectangle(frame, (x, y), (w, h), color, 2)

			if indexIDs[i] in previous:
				previous_box = previous[indexIDs[i]]
				(x2, y2) = (int(previous_box[0]), int(previous_box[1]))
				(w2, h2) = (int(previous_box[2]), int(previous_box[3]))
				p0 = (int(x + (w-x)/2), int(y + (h-y)/2))
				p1 = (int(x2 + (w2-x2)/2), int(y2 + (h2-y2)/2))
				cv2.line(frame, p0, p1, color, 3)

				if intersect(p0, p1, line[0], line[1]):
					counter += 1

			# text = "{}: {:.4f}".format(LABELS[classIDs[i]], confidences[i])
			text = "{}".format(indexIDs[i])
			cv2.putText(frame, text, (x, y - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)
			i += 1

	# draw line
	cv2.line(frame, line[0], line[1], (0, 255, 255), 5)

	# draw counter
	cv2.putText(frame, str(counter), (100,200), cv2.FONT_HERSHEY_DUPLEX, 5.0, (0, 255, 255), 10)
	
	# Calculate and display FPS
	fps_frame_count += 1
	current_time = time.time()
	if fps_frame_count >= 30:  # Update FPS every 30 frames
		elapsed = current_time - fps_start_time
		if elapsed > 0:
			fps = 30.0 / elapsed
		fps_start_time = current_time
		fps_frame_count = 0
	
	# Display FPS on frame (show 0 if not calculated yet)
	display_fps = fps if fps > 0 else 0
	cv2.putText(frame, f"FPS: {display_fps:.1f}", (10, 30), 
		cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)
	
	# Display processing time
	elap = (end - start)
	cv2.putText(frame, f"Process: {elap*1000:.1f}ms", (10, 70), 
		cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

	# Save image file if requested
	if args["save_frames"]:
		cv2.imwrite("output/frame-{}.png".format(frameIndex), frame)

	# Initialize video writer if output path is provided
	if args["output"] is not None:
		if writer is None:
			# initialize our video writer
			fourcc = cv2.VideoWriter_fourcc(*"MJPG")
			writer = cv2.VideoWriter(args["output"], fourcc, 30,
				(frame.shape[1], frame.shape[0]), True)
			print("[INFO] saving video to {}".format(args["output"]))
		
		# write the output frame to disk
		writer.write(frame)

	# Display the frame
	window_name = "Traffic Counter - Real-time" if is_camera else "Traffic Counter - Video"
	cv2.imshow(window_name, frame)
	
	# Press 'q' to quit, or wait for video frames
	if is_camera:
		key = cv2.waitKey(1) & 0xFF
		if key == ord("q"):
			break
	else:
		# For video files, show progress and allow quitting
		key = cv2.waitKey(1) & 0xFF
		if key == ord("q"):
			break
		# Show progress for video files
		if total > 0 and frameIndex % 30 == 0:
			progress = (frameIndex / total) * 100
			print("[INFO] Progress: {:.1f}% ({}/{} frames)".format(progress, frameIndex, total))

	# increase frame index
	frameIndex += 1

# release the file pointers
print("[INFO] cleaning up...")
print(f"[INFO] Toplam geçen araç sayısı: {counter}")
if writer is not None:
	writer.release()
vs.release()
cv2.destroyAllWindows()