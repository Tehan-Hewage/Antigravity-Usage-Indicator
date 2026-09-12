from PIL import Image, ImageDraw
import math
import os

def create_sparkle_image(size):
    """Creates a high-quality RGBA image of the Antigravity AI sparkle at given size."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    pixels = img.load()
    
    cx = size / 2.0
    cy = size / 2.0
    radius = size / 2.0
    
    for y in range(size):
        for x in range(size):
            nx = (x - cx + 0.5) / radius
            ny = (y - cy + 0.5) / radius
            
            r = math.sqrt(nx * nx + ny * ny)
            if r > 0.98:
                continue
                
            # Astroid formula for 4-point sparkle
            p = 0.52
            astroid_dist = (abs(nx) ** p + abs(ny) ** p) ** (1.0 / p)
            
            # Center circular glow
            center_glow = max(0.0, 1.0 - (r / 0.40))
            
            # Edge softness for antialiasing
            edge = 0.88
            sparkle_alpha = max(0.0, min(1.0, (edge - astroid_dist) / 0.15))
            alpha = max(sparkle_alpha, center_glow * 0.9)
            
            # Outer dark protective halo (so it pops on light taskbars)
            halo_alpha = 0.0
            if r < 0.85 and alpha < 0.3:
                halo_dist = max(0.0, min(1.0, (0.85 - r) / 0.3))
                halo_alpha = halo_dist * 0.25
                
            if alpha <= 0.01 and halo_alpha <= 0.01:
                continue
                
            # Color calculation
            t = min(1.0, r / 0.75)
            if t < 0.25:
                # Core: Pure brilliant white
                sub_t = t / 0.25
                cr = int(255 * (1 - sub_t) + 120 * sub_t)
                cg = int(255 * (1 - sub_t) + 225 * sub_t)
                cb = 255
            else:
                # Tips: Vibrant cyan to indigo
                sub_t = (t - 0.25) / 0.75
                cr = int(56 * (1 - sub_t) + 129 * sub_t)
                cg = int(189 * (1 - sub_t) + 140 * sub_t)
                cb = int(248 * (1 - sub_t) + 248 * sub_t)
                
            final_alpha = int(min(1.0, alpha + halo_alpha) * 255)
            if alpha < 0.1 and halo_alpha > 0:
                # Blend with subtle dark halo for light taskbar contrast
                cr = int(cr * 0.4)
                cg = int(cg * 0.4)
                cb = int(cb * 0.4)
                
            pixels[x, y] = (cr, cg, cb, final_alpha)
            
    return img

def main():
    os.makedirs('assets/icons', exist_ok=True)
    os.makedirs('windows/runner/resources', exist_ok=True)
    
    # Generate images at standard Windows icon resolutions
    icon_sizes = [16, 24, 32, 48, 64, 128, 256]
    images = {}
    for sz in icon_sizes:
        images[sz] = create_sparkle_image(sz)
        print(f"Rendered {sz}x{sz}")
        
    # 1. Save PNG assets
    images[256].save('assets/icons/app_icon.png', 'PNG')
    images[32].save('assets/icons/tray_icon.png', 'PNG')
    images[64].save('assets/icons/tray_icon_64.png', 'PNG')
    print("[OK] Saved PNG assets in assets/icons/")
    
    # 2. Save tray_icon.ico (optimized for 16, 24, 32, 48)
    tray_frames = [images[16], images[24], images[32], images[48]]
    images[32].save('assets/icons/tray_icon.ico', format='ICO', sizes=[(16, 16), (24, 24), (32, 32), (48, 48)])
    print("[OK] Saved assets/icons/tray_icon.ico")
    
    # 3. Save windows/runner/resources/app_icon.ico (full Windows icon with 16..256)
    ico_frames = [images[sz] for sz in icon_sizes]
    images[256].save(
        'windows/runner/resources/app_icon.ico',
        format='ICO',
        sizes=[(sz, sz) for sz in icon_sizes]
    )
    print("[OK] Saved windows/runner/resources/app_icon.ico")
    
    # 4. Also copy tray_icon.ico directly to %LOCALAPPDATA%\AntigravityUsageIndicator\
    local_app_data = os.path.expandvars(r'%LOCALAPPDATA%\AntigravityUsageIndicator')
    if os.path.exists(local_app_data):
        target_ico = os.path.join(local_app_data, 'tray_icon.ico')
        images[32].save(target_ico, format='ICO', sizes=[(16, 16), (24, 24), (32, 32), (48, 48)])
        print(f"[OK] Saved {target_ico}")

if __name__ == '__main__':
    main()
