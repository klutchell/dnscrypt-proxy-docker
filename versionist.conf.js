'use strict';

const _ = require('lodash')
const fs = require('fs')
const path = require('path')
const semver = require('balena-semver')
const shell = require('shelljs')
const yaml = require('js-yaml');

const isESR = (version) => {
  return /^\d{4}\.(01|1|04|4|07|7|10)\.\d+$/.test(version)
}

const getMetaResinFromSubmodule = (documentedVersions, history, callback) => {
  const latestDocumented = _.trim(_.last(documentedVersions.sort(semver.compare)))
  // ESR releases do not update meta-balena versions
  if (isESR(latestDocumented)) {
    return callback(null, latestDocumented)
  }
  // This is a hack because git does not update all the relevant files when moving a
  // submodule. Because of this, older repos will still have references to meta-resin
  // and new ones will refer to meta-balena
  const metaName = fs.existsSync('.git/modules/layers/meta-resin', fs.constants.R_OK)
    ? 'meta-resin'
    : 'meta-balena'
  shell.exec(`git --git-dir .git/modules/layers/${metaName} describe --tags --exact-match`, (code, stdout, stderr) => {
    if (code != 0) {
      return callback(new Error(`Could not find ${metaName} submodule`))
    }
    const metaVersion = stdout.replace(/\s/g,'').replace(/^v/g, '')
    if (!metaVersion) {
      return callback(new Error(`Could not determine ${metaName} version from version ${stdout}`))
    }

    const latestDocumentedRevision = latestDocumented.includes('rev')? latestDocumented : `${semver.parse(latestDocumented).version}+rev0`
    // semver.gt will ignore the revision numbers but still compare the version
    // If metaVersion <= latestDocumented then the latestDocumented version is a revision of the current metaVersion
    const latestVersion = semver.gt(metaVersion, latestDocumentedRevision) ? metaVersion : latestDocumentedRevision
    return callback(null, latestVersion)
  })
}

module.exports = {
  addEntryToChangelog: {
    preset: 'prepend',
    fromLine: 3
  },
  getChangelogDocumentedVersions: {
    preset: 'changelog-headers',
    clean: /^v/
  },

  includeCommitWhen: 'has-changelog-entry',
  getIncrementLevelFromCommit: (commit) => {
    return 'patch'
  },
  incrementVersion: (currentVersion, incrementLevel) => {
    if (isESR(currentVersion)) {
      const [majorVersion, minorVersion, patchVersion] = currentVersion.split('.', 3);
      return `${majorVersion}.${minorVersion}.${Number(patchVersion) + 1}`
    }
    const parsedCurrentVersion = semver.parse(currentVersion)
    if ( ! _.isEmpty(parsedCurrentVersion.build) ) {
      let revision = Number(String(parsedCurrentVersion.build).split('rev').pop())
      if (!_.isFinite(revision)) {
        throw new Error(`Could not extract revision number from ${currentVersion}`)
      }
      return  `${parsedCurrentVersion.version}+rev${revision + 1}`
    }
    return `${parsedCurrentVersion.version}`
  },
  updateContract: (cwd, version, callback) => {
      if (/^\d+\.\d+\.\d+$/.test(version) == false &&
          /^\d+\.\d+\.\d+\+rev\d+$/.test(version) == false) {
        return callback(new Error(`Invalid version ${version}`));
      }

      const contract = path.join(cwd, 'balena.yml');
      if (!fs.existsSync(contract)) {
        return callback(null, version);
      }

      const content = yaml.load(fs.readFileSync(contract, 'utf8'));
      content.version = version;
      fs.writeFile(contract, yaml.dump(content), callback);
  },
  getCurrentBaseVersion: getMetaResinFromSubmodule,
  updateVersion: 'update-version-file',

  transformTemplateDataAsync: {
    preset: 'nested-changelogs',
    upstream: [
      {{#upstream}}
      {
        pattern: '{{{pattern}}}',
        repo: '{{repo}}',
        owner: '{{owner}}',
        ref: '{{ref}}'
      },
      {{/upstream}}
    ]
  },

  template: 'default'
}
