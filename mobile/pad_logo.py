from PIL import Image

def pad_image(input_path, output_path, scale_factor=1.6, offset_x_pct=0.05):
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size
    
    # New size
    L = int(max(w, h) * scale_factor)
    
    # White background canvas
    new_img = Image.new("RGBA", (L, L), (255, 255, 255, 255))
    
    # Calculate position
    # Center: (L - w) // 2
    # Offset right: + (w * offset_x_pct)
    x = int((L - w) // 2 + (w * offset_x_pct))
    y = int((L - h) // 2)
    
    # Paste
    new_img.paste(img, (x, y), img)
    
    new_img.save(output_path)
    print(f"Saved padded image to {output_path}")

if __name__ == "__main__":
    pad_image("assets/AKHpng.png", "assets/AKHpng_padded.png")
