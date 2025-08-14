#!/usr/bin/env python3

import sys

def fix_calibration():
    """Fix touchscreen calibration by applying known good matrix"""
    try:
        # Read the current configuration
        with open('/etc/X11/xorg.conf.d/10-touchscreen.conf', 'r') as f:
            content = f.read()
        
        # Replace the empty calibration matrix with the known good one
        old_matrix = 'Option "CalibrationMatrix" ""'
        new_matrix = 'Option "CalibrationMatrix" "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"'
        
        if old_matrix in content:
            content = content.replace(old_matrix, new_matrix)
            
            # Write the updated configuration
            with open('/etc/X11/xorg.conf.d/10-touchscreen.conf', 'w') as f:
                f.write(content)
            
            print("✅ Calibration matrix applied successfully!")
            print("   Matrix: 1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0")
            return True
        else:
            print("❌ Could not find empty calibration matrix in configuration")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = fix_calibration()
    sys.exit(0 if success else 1) 