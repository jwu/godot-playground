# Godot 实验项目 - 工具安装与常用命令
#
# 初始化（首次使用）:
#   cargo install just  # 安装 just 自身（如未安装）
#   just init           # 一键初始化工具 + hooks

# --------------------------------------------------
# 工具安装
# --------------------------------------------------

# 一键初始化：检查并安装缺失工具，启用 commit hook
init:
  @command -v cog >/dev/null 2>&1 || cargo install cocogitto
  @command -v gdscript-formatter >/dev/null 2>&1 || cargo install --git https://github.com/GDQuest/GDScript-formatter
  git config core.hooksPath .githooks
  @echo "✓ 初始化完成"

# 更新已安装的工具到最新版本
upgrade:
  cargo install cocogitto --force
  cargo install --git https://github.com/GDQuest/GDScript-formatter --force

# --------------------------------------------------
# 测试
# --------------------------------------------------

# 运行 gdUnit4 测试（headless，无参=全部测试，有参=指定测试文件）
test *test_file='':
  @cd game && _tf=$(echo "{{test_file}}" | sed 's|^game/||'); if [ -z "$_tf" ]; then \
    GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode --add tests/; \
  else \
    GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode --add "$_tf"; \
  fi

# 同上，但保留 GUI 窗口（调试用，可观察渲染/输入过程）
test-window *test_file='':
  @cd game && _tf=$(echo "{{test_file}}" | sed 's|^game/||'); if [ -z "$_tf" ]; then \
    GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --add tests/; \
  else \
    GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --add "$_tf"; \
  fi

# --------------------------------------------------
# 代码检查
# --------------------------------------------------

# 仅格式检查（无参=全项目，有参=指定文件）
check-fmt *files='':
  @if [ "{{files}}" = "" ]; then \
    find game -name "*.gd" -not -path "game/addons/*" | xargs gdscript-formatter --use-spaces --indent-size 2 --reorder-code --check; \
  else \
    gdscript-formatter --use-spaces --indent-size 2 --reorder-code --check {{files}}; \
  fi

# 格式化（无参=全项目，有参=指定文件）
fmt *files='':
  @if [ "{{files}}" = "" ]; then \
    find game -name "*.gd" -not -path "game/addons/*" | xargs gdscript-formatter --use-spaces --indent-size 2 --reorder-code; \
  else \
    gdscript-formatter --use-spaces --indent-size 2 --reorder-code {{files}}; \
  fi

# 扫描（无参=全项目，有参=指定文件）
lint *files='':
  @if [ "{{files}}" = "" ]; then \
    find game -name "*.gd" -not -path "game/addons/*" | xargs gdscript-formatter lint --disable max-line-length; \
  else \
    gdscript-formatter lint --disable max-line-length {{files}}; \
  fi

# 完整检查（无参=全项目，有参=指定文件）
check *files='':
  @if [ "{{files}}" = "" ]; then \
    _gd=$(find game -name "*.gd" -not -path "game/addons/*"); \
    echo "$_gd" | xargs gdscript-formatter --use-spaces --indent-size 2 --reorder-code --check; \
    echo "$_gd" | xargs gdscript-formatter lint --disable max-line-length; \
  else \
    gdscript-formatter --use-spaces --indent-size 2 --reorder-code --check {{files}}; \
    gdscript-formatter lint --disable max-line-length {{files}}; \
  fi

# 校验 commit message（无参=最新 tag 以来，有参=校验指定消息）
lint-commit msg='':
  @if [ "{{msg}}" = "" ]; then \
    cog check --from-latest-tag --ignore-merge-commits; \
  else \
    cog verify "{{msg}}"; \
  fi
