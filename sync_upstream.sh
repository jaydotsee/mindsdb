#!/bin/bash
echo "Fetching upstream changes..."
git fetch upstream
git checkout main
echo "Merging upstream/main into main..."
git merge upstream/main
echo "Pushing to origin..."
git push origin main
echo "Sync complete!"
