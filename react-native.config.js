const path = require('path');
const fs = require('fs');

const pkg = require('./package.json');

const rootNodeModules = path.join(__dirname, 'node_modules');
const dependencies = {};

if (fs.existsSync(rootNodeModules)) {
  const packages = fs
    .readdirSync(rootNodeModules, { withFileTypes: true })
    .filter((dirent) => dirent.isDirectory() && !dirent.name.startsWith('.'))
    .map((dirent) => dirent.name);

  packages.forEach((packageName) => {
    if (packageName.startsWith('@')) {
      const scopedPackages = fs
        .readdirSync(path.join(rootNodeModules, packageName), {
          withFileTypes: true,
        })
        .filter(
          (dirent) => dirent.isDirectory() && !dirent.name.startsWith('.')
        )
        .map((dirent) => `${packageName}/${dirent.name}`);

      scopedPackages.forEach((scopedPackageName) => {
        if (scopedPackageName !== pkg.name) {
          dependencies[scopedPackageName] = {
            platforms: { android: null, ios: null },
          };
        }
      });
    } else if (packageName !== pkg.name) {
      dependencies[packageName] = { platforms: { android: null, ios: null } };
    }
  });
}

module.exports = {
  dependencies,
};
