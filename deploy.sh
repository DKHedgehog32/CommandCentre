#!/bin/bash

# Set your target branch
BRANCH=KioskBranch

# Optional: Add manifest path if needed
MANIFEST="manifest/package.xml"

echo "🔁 Retrieving metadata from DevB..."
sfdx force:source:retrieve -u DevB -x $MANIFEST

# Stage changes
echo "📦 Staging changes..."
git add .

# Check if there are any changes
if git diff --cached --quiet; then
  echo "ℹ️  No changes detected. Creating empty commit to trigger deploy."
  git commit --allow-empty -m "Trigger deploy at $(date '+%Y-%m-%d %H:%M:%S')"
else
  echo "📝 Committing changes..."
  git commit -m "Deploy: Retrieve updates from DevB on $(date '+%Y-%m-%d %H:%M:%S')"
fi

# Push to GitHub
echo "🚀 Pushing to $BRANCH..."
git push origin $BRANCH

echo "✅ Done. Deployment to DevA will start shortly via GitHub Actions."