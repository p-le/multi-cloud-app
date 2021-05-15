import pytesseract
import argparse
import time
from PIL import Image


def extract(image_path, lang='vie'):
    img = Image.open(image_path)
    return pytesseract.image_to_string(img, lang=lang)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='tesseract-reader', description='Extract text from image using Tesseract OCR')
    parser.add_argument('--image_path', required=True, type=str, help='Path to the image')
    args = parser.parse_args()
    start_ts = time.time()
    result = extract(args.image_path)
    end_ts = time.time()
    print(f"======================= CONTENT =======================")
    print(result)
    print(f"======================= END =======================")
    print(f"Execution Time {round(end_ts - start_ts, 4)} sec")
