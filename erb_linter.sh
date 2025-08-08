#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check if docker-compose service exists
service_exists() {
  docker-compose config --services 2>/dev/null | grep -q "^rails$"
}

# Function to run command in Docker or locally
run_command() {
  local cmd="$1"
  local description="$2"

  echo "$description"

  if command_exists docker-compose && service_exists; then
    echo "  → Running in Docker container (rails service)..."
    docker-compose exec rails bash -c "$cmd"
    return $?
  else
    if command_exists docker-compose; then
      echo "  → docker-compose found but 'rails' service not found in docker-compose.yml"
    else
      echo "  → docker-compose not installed"
    fi

    echo "  → Attempting to run locally..."

    # Extract the main command (first word) to check if it exists locally
    local main_cmd=$(echo "$cmd" | awk '{print $1}')

    if command_exists "$main_cmd"; then
      eval "$cmd"
      return $?
    else
      echo "  ✗ ERROR: '$main_cmd' command not found locally"
      echo "    Please install $main_cmd or ensure docker-compose.yml has a 'rails' service"
      return 1
    fi
  fi
}

# Main script execution
echo "=== Two-Pass ERB Linting Script ==="
echo

# First pass: HTML beautification
if ! run_command "htmlbeautifier app/**/**/*.html.erb" "Running HTML beautification..."; then
  echo "✗ HTML beautification failed!"
  exit 1
fi

echo
echo "✓ HTML beautification completed successfully!"
echo

# Second pass: ERB Lint with autocorrect
if ! run_command "bundle exec erb_lint --lint-all -a" "Running ERB linting with autocorrect..."; then
  echo "✗ ERB linting failed!"
  exit 1
fi

echo
echo "✓ ERB linting completed successfully!"
echo "=== Two-pass linting complete! ==="
