'use strict';

const execSync = require('child_process').execSync;
const fs = require('fs')
const path = require('path')
const os = require('os')

const getAuthor = (commitHash) => {
  return execSync(`git show --quiet --format="%an" ${commitHash}`, {
    encoding: 'utf8'
  }).replace('\n', '');
};

// Install balena-semver to a temporary directory
const install_semver = async () => {
  const tmpDir = path.join(os.tmpdir(), 'versionist')
  fs.mkdirSync(tmpDir, { recursive: true })

  return execSync(`npm install balena-semver@^3.0.2 --prefix "${tmpDir}"`, {
    encoding: 'utf8'
  }).replace('\n', '')
}

const getRev = async (documentedVersions, history, callback) => {
  await install_semver()
  const semver = require(path.join(os.tmpdir(), 'versionist/node_modules/balena-semver'))

  const latestDocumented = documentedVersions.sort(semver.compare).pop().trim()
  if (!latestDocumented) {
    return callback(new Error('Could not determine version from documentedVersions'))
  }
  console.log(`latestDocumented: ${latestDocumented}`)

  // Extract ARG DNSCRYPT_PROXY_VERSION from Dockerfile
  const dockerfile = fs.readFileSync('Dockerfile', 'utf8')
  const argVersion = dockerfile.match(/ARG DNSCRYPT_PROXY_VERSION=(\d+\.\d+\.\d+)/)[1]

  if (!argVersion) {
    return callback(new Error('Could not determine version from Dockerfile'))
  }

  console.log(`argVersion: ${argVersion}`)

  const latestDocumentedRevision = latestDocumented.includes('rev')? latestDocumented : `${semver.parse(latestDocumented).version}+rev0`

  // semver.gt will ignore the revision numbers but still compare the version
  // If argVersion <= latestDocumented then the latestDocumented version is a revision of the current argVersion
  const latestVersion = semver.gt(argVersion, latestDocumentedRevision) ? `${argVersion}+rev0` : latestDocumentedRevision

  console.log(`latestVersion: ${latestVersion}`)
  return callback(null, latestVersion)
}

module.exports = {
  editChangelog: true,
  parseFooterTags: true,
  updateVersion: (cwd, ver, cb) => cb(),

  addEntryToChangelog: {
    preset: 'prepend',
    fromLine: 6
  },

  getChangelogDocumentedVersions: {
    preset: 'changelog-headers',
    clean: /^v/
  },

  includeCommitWhen: (commit) => { return true; },
  getIncrementLevelFromCommit: (commit) => {
    return 'patch'
  },
  incrementVersion: (currentVersion, incrementLevel) => {
    const semver = require(path.join(os.tmpdir(), 'versionist/node_modules/balena-semver'))

    const parsedCurrentVersion = semver.parse(currentVersion)
    console.log(`parsedCurrentVersion: ${JSON.stringify(parsedCurrentVersion)}`)
    if (parsedCurrentVersion.build != null && parsedCurrentVersion.build.length > 0) {
      let revision = Number(String(parsedCurrentVersion.build).split('rev').pop())
      console.log(`revision: ${revision}`)
      if (!Number.isFinite(revision)) {
        throw new Error(`Could not extract revision number from ${currentVersion}`)
      }
      return  `${parsedCurrentVersion.version}+rev${revision + 1}`
    }
    return `${parsedCurrentVersion.version}`
  },

  getCurrentBaseVersion: getRev,
  // If a 'changelog-entry' tag is found, use this as the subject rather than the
  // first line of the commit.
  transformTemplateData: (data) => {
    data.commits.forEach((commit) => {
      commit.subject = commit.footer['changelog-entry'] || commit.subject;
      commit.author = getAuthor(commit.hash);
    });

    return data;
  }
}
