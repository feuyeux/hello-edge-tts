#!/bin/bash

# 依赖更新脚本
# 用法: ./scripts/update-dependencies.sh [language]
# 支持的语言: python, java, dart, rust, all

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 更新 Python 依赖
update_python() {
    log_info "更新 Python 依赖..."
    
    cd "$PROJECT_ROOT/hello-edge-tts-python"
    
    if [ ! -f "requirements.txt" ]; then
        log_warning "未找到 requirements.txt 文件"
        return 1
    fi
    
    # 创建虚拟环境
    python -m venv venv
    source venv/bin/activate
    
    # 安装 pip-tools
    pip install --upgrade pip pip-tools
    
    # 如果没有 requirements.in，从 requirements.txt 创建
    if [ ! -f "requirements.in" ]; then
        cp requirements.txt requirements.in
    fi
    
    # 更新依赖
    pip-compile --upgrade requirements.in
    
    # 清理虚拟环境
    deactivate
    rm -rf venv
    
    log_success "Python 依赖更新完成"
}

# 更新 Java 依赖
update_java() {
    log_info "更新 Java 依赖..."
    
    cd "$PROJECT_ROOT/hello-edge-tts-java"
    
    if [ ! -f "pom.xml" ]; then
        log_warning "未找到 pom.xml 文件"
        return 1
    fi
    
    # 更新依赖版本
    mvn versions:use-latest-releases
    mvn versions:update-properties
    
    # 清理备份文件
    find . -name "*.versionsBackup" -delete
    
    log_success "Java 依赖更新完成"
}

# 更新 Dart 依赖
update_dart() {
    log_info "更新 Dart 依赖..."
    
    cd "$PROJECT_ROOT/hello-edge-tts-dart"
    
    if [ ! -f "pubspec.yaml" ]; then
        log_warning "未找到 pubspec.yaml 文件"
        return 1
    fi
    
    # 更新依赖
    dart pub upgrade
    
    log_success "Dart 依赖更新完成"
}

# 更新 Rust 依赖
update_rust() {
    log_info "更新 Rust 依赖..."
    
    cd "$PROJECT_ROOT/hello-edge-tts-rust"
    
    if [ ! -f "Cargo.toml" ]; then
        log_warning "未找到 Cargo.toml 文件"
        return 1
    fi
    
    # 安装 cargo-edit（如果未安装）
    if ! command -v cargo-upgrade &> /dev/null; then
        cargo install cargo-edit
    fi
    
    # 更新依赖
    cargo upgrade
    cargo update
    
    log_success "Rust 依赖更新完成"
}

# 运行安全审计
run_security_audit() {
    log_info "运行安全审计..."
    
    # Python 安全审计
    if [ -d "$PROJECT_ROOT/hello-edge-tts-python" ]; then
        log_info "Python 安全审计..."
        cd "$PROJECT_ROOT/hello-edge-tts-python"
        python -m pip install safety
        safety check -r requirements.txt || log_warning "Python 安全审计发现问题"
    fi
    
    # Rust 安全审计
    if [ -d "$PROJECT_ROOT/hello-edge-tts-rust" ]; then
        log_info "Rust 安全审计..."
        cd "$PROJECT_ROOT/hello-edge-tts-rust"
        if ! command -v cargo-audit &> /dev/null; then
            cargo install cargo-audit
        fi
        cargo audit || log_warning "Rust 安全审计发现问题"
    fi
    
    # Java 安全审计
    if [ -d "$PROJECT_ROOT/hello-edge-tts-java" ]; then
        log_info "Java 安全审计..."
        cd "$PROJECT_ROOT/hello-edge-tts-java"
        mvn org.owasp:dependency-check-maven:check || log_warning "Java 安全审计发现问题"
    fi
    
    log_success "安全审计完成"
}

# 显示帮助信息
show_help() {
    echo "依赖更新脚本"
    echo ""
    echo "用法: $0 [选项] [语言]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -s, --security 运行安全审计"
    echo ""
    echo "支持的语言:"
    echo "  python         更新 Python 依赖"
    echo "  java           更新 Java 依赖"
    echo "  dart           更新 Dart 依赖"
    echo "  rust           更新 Rust 依赖"
    echo "  all            更新所有语言的依赖"
    echo ""
    echo "示例:"
    echo "  $0 python      # 只更新 Python 依赖"
    echo "  $0 all         # 更新所有依赖"
    echo "  $0 --security  # 运行安全审计"
}

# 主函数
main() {
    local language=""
    local run_audit=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--security)
                run_audit=true
                shift
                ;;
            python|java|dart|rust|all)
                language="$1"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定语言，默认为 all
    if [ -z "$language" ] && [ "$run_audit" = false ]; then
        language="all"
    fi
    
    log_info "开始依赖更新..."
    
    # 根据参数执行相应操作
    case $language in
        python)
            update_python
            ;;
        java)
            update_java
            ;;
        dart)
            update_dart
            ;;
        rust)
            update_rust
            ;;
        all)
            update_python || true
            update_java || true
            update_dart || true
            update_rust || true
            ;;
    esac
    
    # 运行安全审计
    if [ "$run_audit" = true ]; then
        run_security_audit
    fi
    
    log_success "依赖更新完成！"
}

# 创建 scripts 目录（如果不存在）
mkdir -p "$PROJECT_ROOT/scripts"

# 运行主函数
main "$@"