#!/bin/bash

# MindsDB Startup Script with Driver Configuration

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MINDSDB_PORT=${MINDSDB_PORT:-47334}
MINDSDB_HOST=${MINDSDB_HOST:-0.0.0.0}
MINDSDB_CONFIG_PATH=${MINDSDB_CONFIG_PATH:-~/.mindsdb/config.json}
MINDSDB_STORAGE_PATH=${MINDSDB_STORAGE_PATH:-~/.mindsdb}

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[MINDSDB]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Python dependencies for drivers
install_driver_dependencies() {
    print_status "Installing driver dependencies..."
    
    # Core database drivers
    pip install --upgrade \
        psycopg2-binary \
        pymongo \
        mysql-connector-python \
        
        redis \
        cassandra-driver \
        neo4j \
        clickhouse-driver \
        snowflake-connector-python \
        elasticsearch \
        influxdb-client

    # MCP (Model Context Protocol) dependencies
    pip install --upgrade \
        anthropic \
        openai \
        langchain \
        langchain-anthropic \
        mcp

    # Additional useful drivers
    pip install --upgrade \
        boto3 \
        google-cloud-bigquery \
        azure-storage-blob \
        requests \
        beautifulsoup4 \
        selenium
}

# Function to create MindsDB config
create_config() {
    print_status "Creating MindsDB configuration..."
    
    mkdir -p "$(dirname "$MINDSDB_CONFIG_PATH")"
    
    cat > "$MINDSDB_CONFIG_PATH" << EOF
{
    "api": {
        "http": {
            "host": "$MINDSDB_HOST",
            "port": $MINDSDB_PORT
        }
    },
    "storage_dir": "$MINDSDB_STORAGE_PATH",
    "debug": false,
    "integrations": {
        "default_postgres": {
            "enabled": true,
            "host": "localhost",
            "port": 5432,
            "publish": true
        },
        "default_mongodb": {
            "enabled": true,
            "host": "localhost", 
            "port": 27017,
            "publish": true
        },
        "default_mysql": {
            "enabled": true,
            "host": "localhost",
            "port": 3306,
            "publish": true
        },
        "default_redis": {
            "enabled": true,
            "host": "localhost",
            "port": 6379,
            "publish": true
        }
    },
    "ml_handlers": {
        "openai": {
            "enabled": true
        },
        "anthropic": {
            "enabled": true
        },
        "huggingface": {
            "enabled": true
        }
    }
}
EOF
    
    print_status "Configuration created at: $MINDSDB_CONFIG_PATH"
}

# Function to check system requirements
check_requirements() {
    print_header "Checking system requirements..."
    
    if ! command_exists python3; then
        print_error "Python3 is required but not installed."
        exit 1
    fi
    
    if ! command_exists pip; then
        print_error "pip is required but not installed."
        exit 1
    fi
    
    # Check Python version
    python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    print_status "Python version: $python_version"
    
    if ! command_exists mindsdb; then
        print_warning "MindsDB not found in PATH. Installing..."
        pip install mindsdb
    fi
    
    print_status "System requirements check completed."
}

# Function to setup environment variables
setup_environment() {
    print_status "Setting up environment variables..."
    
    # Set common environment variables
    export MINDSDB_STORAGE_PATH="$MINDSDB_STORAGE_PATH"
    export MINDSDB_CONFIG_PATH="$MINDSDB_CONFIG_PATH"
    
    # Optional: Set API keys if provided as arguments or environment variables
    if [ -n "$OPENAI_API_KEY" ]; then
        export OPENAI_API_KEY="$OPENAI_API_KEY"
        print_status "OpenAI API key configured"
    fi
    
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
        print_status "Anthropic API key configured"
    fi
}

# Function to start MindsDB
start_mindsdb() {
    print_header "Starting MindsDB..."
    print_status "Host: $MINDSDB_HOST"
    print_status "Port: $MINDSDB_PORT"
    print_status "Config: $MINDSDB_CONFIG_PATH"
    print_status "Storage: $MINDSDB_STORAGE_PATH"
    
    # Start MindsDB with configuration
    mindsdb \
        --config="$MINDSDB_CONFIG_PATH" \
        --api=http \
        --verbose
}

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --port PORT        Set MindsDB port (default: 47334)"
    echo "  -h, --host HOST        Set MindsDB host (default: 0.0.0.0)"
    echo "  -c, --config PATH      Set config file path"
    echo "  -s, --storage PATH     Set storage directory path"
    echo "  --install-deps         Install driver dependencies"
    echo "  --create-config        Create/recreate configuration file"
    echo "  --help                 Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  OPENAI_API_KEY         OpenAI API key"
    echo "  ANTHROPIC_API_KEY      Anthropic API key"
    echo "  MINDSDB_PORT          MindsDB port"
    echo "  MINDSDB_HOST          MindsDB host"
    echo "  MINDSDB_CONFIG_PATH   Config file path"
    echo "  MINDSDB_STORAGE_PATH  Storage directory path"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            MINDSDB_PORT="$2"
            shift 2
            ;;
        -h|--host)
            MINDSDB_HOST="$2"
            shift 2
            ;;
        -c|--config)
            MINDSDB_CONFIG_PATH="$2"
            shift 2
            ;;
        -s|--storage)
            MINDSDB_STORAGE_PATH="$2"
            shift 2
            ;;
        --install-deps)
            install_driver_dependencies
            exit 0
            ;;
        --create-config)
            create_config
            exit 0
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_header "MindsDB Startup Script"
    echo "========================================"
    
    # Check requirements
    check_requirements
    
    # Setup environment
    setup_environment
    
    # Create config if it doesn't exist
    if [ ! -f "$MINDSDB_CONFIG_PATH" ]; then
        print_warning "Config file not found. Creating default configuration..."
        create_config
    fi
    
    # Create storage directory
    mkdir -p "$MINDSDB_STORAGE_PATH"
    
    print_status "Starting MindsDB with the following drivers enabled:"
    echo "  ✓ PostgreSQL"
    echo "  ✓ MongoDB" 
    echo "  ✓ MySQL"
    echo "  ✓ Redis"
    echo "  ✓ MCP (Model Context Protocol)"
    echo "  ✓ OpenAI"
    echo "  ✓ Anthropic"
    echo "  ✓ HuggingFace"
    echo ""
    
    # Start MindsDB
    start_mindsdb
}

# Handle script interruption
trap 'print_warning "Script interrupted. Exiting..."; exit 1' INT TERM

# Execute main function
main "$@"