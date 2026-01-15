# ---------------- IMPORT ----------------
import numpy as np
import argparse
import time
import cv2
import os
import glob
from sort import *

# ---------------- ARGPARSE ----------------
ap = argparse.ArgumentParser()
ap.add_argument("-i", "--input", type=str, default=None, help="Video file path (leave empty for Pi Camera)")
ap.add_argument("-o", "--output", type=str, default=None, help="Optional output video")
ap.add_argument("--confidence", type=float, default=0.25, help="Minimum confidence for detections")
ap.add_argument("--threshold", type=float, default=0.5, help="NMS threshold")
ap.add_argument("--save-frames", action="store_true", help="Save individual frames")
args = vars(ap.parse_args())

# ---------------- OUTPUT DIR ----------------
if args["save_frames"]:
    os.makedirs("output", exist_ok=True)
    for f in glob.glob("output/*.png"):
        os.remove(f)

# ---------------- SORT TRACKER ----------------
tracker = Sort()
memory = {}
counter_line = [(43, 200), (550, 250)]  # Çizgi koordinatları
counter = 0



# ---------------- GEOMETRY ----------------
def ccw(A, B, C):
    return (C[1]-A[1]) * (B[0]-A[0]) > (B[1]-A[1]) * (C[0]-A[0])

def intersect(A, B, C, D):
    return ccw(A, C, D) != ccw(B, C, D) and ccw(A, B, C) != ccw(A, B, D)

# ---------------- YOLO LOAD ----------------
YOLO_DIR = "yolo-tiny"  # klasörünüzde yolov3-tiny.cfg ve yolov3-tiny.weights olmalı
labelsPath = os.path.join(YOLO_DIR, "coco.names")
LABELS = open(labelsPath).read().strip().split("\n")

np.random.seed(42)
COLORS = np.random.randint(0, 255, size=(200, 3), dtype="uint8")

weightsPath = os.path.join(YOLO_DIR, "yolov3-tiny.weights")
configPath = os.path.join(YOLO_DIR, "yolov3-tiny.cfg")

print("[INFO] Loading YOLO-Tiny model...")
net = cv2.dnn.readNetFromDarknet(configPath, weightsPath)
net.setPreferableBackend(cv2.dnn.DNN_BACKEND_OPENCV)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)

ln = net.getLayerNames()
output_layers = net.getUnconnectedOutLayers().flatten()
ln = [ln[i - 1] for i in output_layers]

# ---------------- INPUT SOURCE ----------------
USE_PICAMERA = False
if args["input"] is None:
    USE_PICAMERA = True
    print("[INFO] Using Pi Camera...")
    from picamera2 import Picamera2
    picam2 = Picamera2()
    config = picam2.create_video_configuration(main={"size": (320, 320), "format": "RGB888"})
    picam2.configure(config)
    picam2.start()
    time.sleep(1)
else:
    if not os.path.exists(args["input"]):
        print("[ERROR] Video file not found:", args["input"])
        exit(1)
    print("[INFO] Opening video file...")
    vs = cv2.VideoCapture(args["input"])

# ---------------- MAIN LOOP ----------------
(W, H) = (320, 320)  # sabit çözünürlük
fps_start = time.time()
fps_count = 0
fps = 0

print("[INFO] Video stream started. Press 'q' to quit.")
counted_ids = set()

ZONE_TOP = 200
ZONE_BOTTOM = 260
while True:
    if USE_PICAMERA:
        frame = picam2.capture_array()
        frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
        grabbed = True
    else:
        grabbed, frame = vs.read()
        if grabbed:
            frame = cv2.resize(frame, (W, H))

    if not grabbed:
        break

    # ---------------- YOLO DETECTION ----------------
    blob = cv2.dnn.blobFromImage(frame, 1/255.0, (320, 320), swapRB=True, crop=False)
    net.setInput(blob)
    layerOutputs = net.forward(ln)

    boxes, confidences, classIDs = [], [], []
    for output in layerOutputs:
        for detection in output:
            scores = detection[5:]
            classID = np.argmax(scores)
            confidence = scores[classID]
            if confidence > args["confidence"]:
                box = detection[0:4] * np.array([W, H, W, H])
                (cX, cY, w, h) = box.astype("int")
                x = int(cX - w/2)
                y = int(cY - h/2)
                boxes.append([x, y, int(w), int(h)])
                confidences.append(float(confidence))
                classIDs.append(classID)

    idxs = cv2.dnn.NMSBoxes(boxes, confidences, args["confidence"], args["threshold"])

    dets = []
    if len(idxs) > 0:
        for i in idxs.flatten():
            if LABELS[classIDs[i]] not in ["car", "truck", "bus", "motorbike"]:
                continue
            print("Detected:", LABELS[classIDs[i]], confidences[i])
            x, y, w, h = boxes[i]
            dets.append([x, y, x+w, y+h, confidences[i]])

    if len(dets) == 0:
        dets = np.empty((0, 5))
    else:
        dets = np.array(dets)

    if dets.shape[0] == 0:
        tracks = np.empty((0, 5))
    else:
        tracks = tracker.update(dets)

    previous = memory.copy()
    memory = {}

    # ---------------- TRACKING & COUNTING ----------------
    line_y = 220 
    for track in tracks:
        track_id = int(track[4])
        x1, y1, x2, y2 = map(int, track[:4])
        memory[track_id] = [x1, y1, x2, y2]
        color = COLORS[track_id % len(COLORS)].tolist()
        cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
        cv2.putText(frame, str(track_id), (x1, y1-5), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)

         # çizginin Y konumu (görüntüne göre ayarla)

        cx = (x1 + x2) // 2
        cy = (y1 + y2) // 2

        if ZONE_TOP <= cy <= ZONE_BOTTOM:
            if track_id not in counted_ids:
                counter += 1
                counted_ids.add(track_id)
                print("COUNTED:", track_id)


    # ---------------- DRAW LINE & INFO ----------------
    cv2.rectangle(
        frame,
        (0, ZONE_TOP),
        (W, ZONE_BOTTOM),
        (0, 255, 255),
        2
    )
    cv2.putText(frame, f"Count: {counter}", (10, 30), cv2.FONT_HERSHEY_DUPLEX, 1, (0, 255, 255), 2)

    fps_count += 1
    if fps_count >= 10:
        elapsed = time.time() - fps_start
        fps = fps_count / elapsed if elapsed > 0 else 0
        fps_start = time.time()
        fps_count = 0
    cv2.putText(frame, f"FPS: {fps:.1f}", (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)

    cv2.imshow("Traffic Counter", frame)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

# ---------------- CLEANUP ----------------
print("[INFO] Total car count:", counter)
if USE_PICAMERA:
    picam2.stop()
else:
    vs.release()
cv2.destroyAllWindows()
