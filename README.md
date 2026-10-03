## CI/CD

### Development

Push to `auto_development`:

    git push origin auto_development

This runs Flutter CI:
- Flutter analyze
- Flutter tests

### Release

1. Update version in pubspec.yaml

    version: 1.0.32+32

2. Commit and push changes.

3. Create release tag:

    git tag v1.0.32

4. Push tag:

    git push origin v1.0.32

The release tag triggers:
- Android CD → Google Play Internal Testing
- iOS CD → TestFlight
