import cv2
from flask import Flask,jsonify

app = Flask(__name__)

@app.route('/img_flask/<string:n>', methods=['GET', 'POST'])
def img_processing(n):
    img = cv2.imread(n)
    img = cv2.cvtColor(img,cv2.COLOR_BGR2RGB)
    gray = cv2.cvtColor(img,cv2.COLOR_RGB2GRAY)
    blr = cv2.medianBlur(gray,11)
    _,th = cv2.threshold(blr,182,255,cv2.THRESH_BINARY)
    dilate = cv2.dilate(th,(11,11),iterations=7)
    erode = cv2.erode(dilate,(11,11),iterations=7)

    res = img.copy()
    defective = False
    contour,heirarchy = cv2.findContours(erode,cv2.RETR_CCOMP,cv2.CHAIN_APPROX_SIMPLE)
    for i in range(len(contour)):
        if (erode==0).sum() > 0:
            defective = True
            if heirarchy[0][i][3] != 0:
                cv2.drawContours(res,contour,i,(210,20,30),1)

    result = {
        "Defective": defective,
        "File_name": n
    }
    return jsonify(result)

if __name__ == "__main__":
    host = "192.168.43.246"
    port = 65432
    app.run(host=host,port=port)