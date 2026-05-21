FEATURE=${1:-auth}
BASE="lib/src/features/$FEATURE"
DIRS=("data/datasources" "data/models" "data/repositories" "domain/entities" "domain/repositories" "domain/usecases" "presentation/cubit" "presentation/pages" "presentation/widgets")

echo "Checking $FEATURE feature..."
for DIR in "${DIRS[@]}"; do
  FULL_PATH="$BASE/$DIR"
  if [ -d "$FULL_PATH" ]; then
    echo "  [SKIP]    $FULL_PATH"
  else
    mkdir -p "$FULL_PATH"
    echo "  [CREATED] $FULL_PATH"
  fi
done
echo "Done! $FEATURE feature ready!"
