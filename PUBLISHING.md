# Publishing Guide

This document outlines the steps to publish `@2security/lunar-date-picker` to npm.

## 📋 Prerequisites

### 1. Access Requirements

- [ ] npm account with publish permissions to `@2security` organization
- [ ] Logged in to npm CLI: `npm login`
- [ ] Write access to the GitHub repository

### 2. Environment Setup

- [ ] Node.js 18+ installed
- [ ] Yarn 3.6.1+ installed
- [ ] All dependencies installed: `yarn install`
- [ ] React Native development environment set up (for testing)

### 3. Verify npm Authentication

```bash
npm whoami
# Should return your npm username

npm access list packages @2security
# Should show your access to the organization
```

## 🔍 Pre-Publish Checklist

### 1. Code Quality

- [ ] All tests pass: `yarn test`
- [ ] Linting passes: `yarn lint`
- [ ] TypeScript compilation: `yarn typecheck`
- [ ] Native code generation: `yarn nitrogen`

### 2. Build Verification

- [ ] Library builds successfully: `yarn prepare`
- [ ] Example app runs on iOS: `yarn example ios`
- [ ] Example app runs on Android: `yarn example android`

### 3. Documentation

- [ ] README.md is up to date
- [ ] CHANGELOG.md includes new features/fixes
- [ ] API documentation reflects changes
- [ ] Version number in package.json is correct

### 4. Testing

- [ ] Unit tests pass
- [ ] Integration tests with example app
- [ ] Test on both iOS and Android devices
- [ ] Verify all new features work correctly

## 🚀 Publishing Process

### Option 1: Automated Release (Recommended)

Using `release-it` for automated versioning and publishing:

```bash
# For patch release (bug fixes)
yarn release-it patch

# For minor release (new features)
yarn release-it minor

# For major release (breaking changes)
yarn release-it major

# Or let release-it suggest the version based on conventional commits
yarn release-it
```

The automated process will:

- Bump version in package.json
- Generate CHANGELOG.md entry
- Create git tag
- Build the library
- Publish to npm
- Create GitHub release

### Option 2: Manual Release

If you need more control over the process:

#### Step 1: Version Bump

```bash
# Update version in package.json manually or use npm version
npm version patch  # for bug fixes
npm version minor  # for new features
npm version major  # for breaking changes
```

#### Step 2: Build and Test

```bash
# Clean previous builds
yarn clean

# Generate native code
yarn nitrogen

# Build the library
yarn prepare

# Final test
yarn test
yarn lint
yarn typecheck
```

#### Step 3: Publish

```bash
# Publish to npm
npm publish --access public

# Or use yarn
yarn publish --access public
```

#### Step 4: Create Git Tag and Release

```bash
# Commit version bump
git add .
git commit -m "chore: release v$(node -p "require('./package.json').version")"

# Create and push tag
git tag v$(node -p "require('./package.json').version")
git push origin main --tags

# Create GitHub release manually through web interface
```

## 🧪 Post-Publish Verification

### 1. Package Verification

```bash
# Check if package is available on npm
npm view @2security/lunar-date-picker

# Verify latest version
npm view @2security/lunar-date-picker version

# Check package contents
npm pack --dry-run
```

### 2. Installation Test

Create a test project to verify the published package:

```bash
# Create test project
npx react-native init TestProject
cd TestProject

# Install your published package
npm install @2security/lunar-date-picker react-native-nitro-modules

# Test basic import
echo "import { configure } from '@2security/lunar-date-picker';" > test.js
node test.js
```

### 3. Documentation Updates

- [ ] Update README badges if needed
- [ ] Update CHANGELOG.md with release notes
- [ ] Create GitHub release with detailed notes
- [ ] Update any external documentation

## 🔧 Troubleshooting

### Common Issues

#### 1. "Permission denied" when publishing

```bash
# Re-login to npm
npm logout
npm login

# Verify permissions
npm access list packages @2security
```

#### 2. "Version already exists"

```bash
# Check current published version
npm view @2security/lunar-date-picker version

# Bump version and try again
npm version patch
npm publish --access public
```

#### 3. Build failures

```bash
# Clean everything and rebuild
yarn clean
rm -rf node_modules
yarn install
yarn nitrogen
yarn prepare
```

#### 4. Example app doesn't work after publish

- Verify all peer dependencies are correctly specified
- Check that native code is properly generated
- Test installation in a fresh React Native project

### Publishing LBA (dist-tag `lba`)

Use this flow to release a Lotus Booking App-specific prerelease without affecting `latest` (stable):

```bash
# 1) Ensure clean git or commit changes
git add -A && git commit -m "chore: prepare release 0.1.15-lba"

# 2) Set version to LBA
npm version 0.1.15-lba
# (If you do not want auto git tag/commit: npm version 0.1.15-lba --no-git-tag-version)

# 3) Build
yarn nitrogen
yarn prepare

# 4) Publish under 'lba' dist-tag
npm publish --tag lba --access public

# 5) Push commit and tag (if created)
git push && git push --tags
```

Install:

```bash
yarn add @2security/lunar-date-picker@lba
# or
yarn add @2security/lunar-date-picker@0.1.15-lba
```

Notes:

- `yarn add @2security/lunar-date-picker` always resolves to `latest` (stable).
- You can manage tags if needed:

```bash
npm dist-tag add @2security/lunar-date-picker@0.1.15-lba lba
npm dist-tag ls @2security/lunar-date-picker
```

### Publishing Beta/Alpha Versions

For testing before official release:

```bash
# Publish beta version
npm version prerelease --preid=beta
npm publish --access public --tag beta

# Install beta version
npm install @2security/lunar-date-picker@beta
```

### Working with npm dist-tags (general)

Dist-tags cho phép duy trì nhiều kênh cài đặt (ví dụ: `latest`, `beta`, `next`, `lba`).

```bash
# Publish một version với tag tuỳ chỉnh (không ảnh hưởng 'latest')
npm publish --tag <tag-name> --access public

# Gắn một tag vào version đã publish
npm dist-tag add @2security/lunar-date-picker@<version> <tag-name>

# Liệt kê các tag hiện tại
npm dist-tag ls @2security/lunar-date-picker

# Gỡ một tag (không xoá version)
npm dist-tag rm @2security/lunar-date-picker <tag-name>

# Promote: đặt một version làm 'latest'
npm dist-tag add @2security/lunar-date-picker@<version> latest

# Cách cài đặt từ client
yarn add @2security/lunar-date-picker@<tag-name>
# hoặc pin cụ thể một version
yarn add @2security/lunar-date-picker@<version>
```

## 📝 Release Notes Template

When creating GitHub releases, use this template:

```markdown
## What's New in v[VERSION]

### ✨ New Features

- Feature 1 description
- Feature 2 description

### 🐛 Bug Fixes

- Fix 1 description
- Fix 2 description

### 🔧 Improvements

- Improvement 1 description
- Improvement 2 description

### 💥 Breaking Changes (if any)

- Breaking change description
- Migration guide

### 📚 Documentation

- Documentation updates

## Installation

\`\`\`bash
npm install @2security/lunar-date-picker@[VERSION]
\`\`\`

## Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed changes.
```

## 🔄 Continuous Integration

### GitHub Actions (Future Enhancement)

Consider setting up automated publishing with GitHub Actions:

```yaml
# .github/workflows/publish.yml
name: Publish Package

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          registry-url: 'https://registry.npmjs.org'

      - name: Install dependencies
        run: yarn install --frozen-lockfile

      - name: Build package
        run: |
          yarn nitrogen
          yarn prepare

      - name: Publish to npm
        run: npm publish --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## 📞 Support

If you encounter issues during publishing:

1. Check this guide first
2. Verify all prerequisites are met
3. Test in a clean environment
4. Contact the maintainer: duongthptnt@gmail.com
5. Create an issue in the repository

---

**Remember**: Always test thoroughly before publishing, and consider using beta releases for major changes!
