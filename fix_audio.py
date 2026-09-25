import re

file_path = r"d:\Work\CodeAra\SnakeAra\lib\services\sound_service.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Remove all AudioPool? _poolName;
content = re.sub(r"\s*AudioPool\?\s+_\w+Pool;", "", content)

# Remove all _poolName = await FlameAudio.createPool(...);
content = re.sub(r"\s*_\w+Pool\s*=\s*await\s+FlameAudio\.createPool[^;]+;", "", content)

# Remove the comment about creating pools
content = re.sub(r"\s*// Create Flame AudioPool instances for SFX to avoid audio lag & player leaks", "", content)

# Replace the block:
# if (_pool != null) {
#   _pool!.start(volume: X);
# } else {
#   FlameAudio.play('...', volume: X);
# }
# With just FlameAudio.play('...', volume: X);

pattern = r"if\s*\(_\w+Pool\s*!=\s*null\)\s*\{\s*_\w+Pool!\.start\(([^)]+)\);\s*\}\s*else\s*\{\s*(FlameAudio\.play\([^;]+;\))\s*\}"

def replacer(match):
    # match.group(2) is the FlameAudio.play(...) line
    return match.group(2)

content = re.sub(pattern, replacer, content)

# Remove the pool dispose calls in onClose
content = re.sub(r"\s*_\w+Pool\?\.dispose\(\);", "", content)

# Add debounce to playEatApple
eat_apple_pattern = r"(void playEatApple\(\)\s*\{)(.*?)(if \(!_initialized \|\| !_isSfxEnabled\) return;)"
def eat_apple_replacer(match):
    return match.group(1) + """
    final now = DateTime.now();
    if (_lastEatAppleTime != null && now.difference(_lastEatAppleTime!).inMilliseconds < 50) {
      return;
    }
    _lastEatAppleTime = now;
""" + match.group(2) + match.group(3)

content = re.sub(eat_apple_pattern, eat_apple_replacer, content, flags=re.DOTALL)

# Also need to declare _lastEatAppleTime if not declared
if "_lastEatAppleTime" not in content:
    content = content.replace("DateTime? _lastLaserDeathTime;", "DateTime? _lastLaserDeathTime;\n  DateTime? _lastEatAppleTime;")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Audio Pools removed and code updated.")
