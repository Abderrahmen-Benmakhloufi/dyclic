import os
import sys
from PIL import Image

def remove_white_background(img_path, output_path=None, tolerance=30, feather=True):
    """
    Removes white / near-white background from an image and saves it with transparent background.
    tolerance: how far from (255, 255, 255) to consider white (e.g. 240+).
    """
    if output_path is None:
        output_path = img_path

    img = Image.open(img_path).convert('RGBA')
    datas = img.getdata()
    
    new_data = []
    threshold = 255 - tolerance
    
    for item in datas:
        r, g, b, a = item
        # If it's near-white
        if r >= threshold and g >= threshold and b >= threshold:
            # Smooth feathering near threshold edge
            diff = max(255 - r, 255 - g, 255 - b)
            if feather and diff < tolerance:
                # Gradual alpha fade
                alpha = int((diff / tolerance) * 255)
                new_data.append((r, g, b, alpha))
            else:
                new_data.append((255, 255, 255, 0))
        else:
            new_data.append((r, g, b, a))

    img.putdata(new_data)
    img.save(output_path, "PNG")
    print(f"Processed: {output_path}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        path = sys.argv[1]
        if os.path.isfile(path):
            remove_white_background(path)
        elif os.path.isdir(path):
            for f in os.listdir(path):
                if f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
                    remove_white_background(os.path.join(path, f))
    else:
        print("Usage: python remove_white_bg.py <image_path_or_folder>")
