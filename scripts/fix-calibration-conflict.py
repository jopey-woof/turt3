#!/usr/bin/env python3

import sys

def fix_calibration_conflict():
    """Fix the conflicting calibration matrix in 99-calibration.conf"""
    try:
        # Read the conflicting configuration
        with open('/etc/X11/xorg.conf.d/99-calibration.conf', 'r') as f:
            content = f.read()
        
        # Replace the wrong calibration matrix with the correct one
        old_matrix = 'Option "CalibrationMatrix" "1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"'
        new_matrix = 'Option "CalibrationMatrix" "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"'
        
        if old_matrix in content:
            content = content.replace(old_matrix, new_matrix)
            
            # Write the updated configuration
            with open('/etc/X11/xorg.conf.d/99-calibration.conf', 'w') as f:
                f.write(content)
            
            print("✅ Fixed conflicting calibration matrix in 99-calibration.conf!")
            print("   Changed from: 1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0")
            print("   Changed to:   1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0")
            return True
        else:
            print("❌ Could not find the conflicting calibration matrix")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = fix_calibration_conflict()
    sys.exit(0 if success else 1) 