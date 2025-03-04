'use strict';

const execSync = require('child_process').execSync;
const fs = require('fs')
const semver = require('versionist/node_modules/balena-semver')

const getAuthor = (commitHash) => {
  return execSync(`git show --quiet --format="%an" ${commitHash}`, {
    encoding: 'utf8'
  }).replace('\n', '');
};

const getRev = (documentedVersions, history, callback) => {

  // Extract ARG DNSCRYPT_PROXY_VERSION from Dockerfile
  const dockerfile = fs.readFileSync('Dockerfile', 'utf8')
  const argVersion = dockerfile.match(/ARG DNSCRYPT_PROXY_VERSION=(\d+\.\d+\.\d+)/)[1]

  if (!argVersion) {
    return callback(new Error('Could not determine version from Dockerfile'))
  }

  // Get the latest git tag matching semver
  const gitVersion = execSync(`git tag --sort=-v:refname | grep -E '^v?[0-9]+\\.[0-9]+\\.[0-9]+(\\+rev[0-9]+)?$' | head -n1`, {
    encoding: 'utf8'
  }).replace('\n', '').replace(/^v/, '')

  // When the version does not include a revision number, +rev0 is implied and must be added here
  // in order for the increment to work correctly
  const latestDocumented = gitVersion.includes('rev') ? gitVersion : `${gitVersion}+rev0`

  console.log(`argVersion: ${argVersion}`)
  console.log(`gitVersion: ${gitVersion}`)
  console.log(`latestDocumented: ${latestDocumented}`)

  // process.exit(0)

  // semver.gt will ignore the revision numbers but still compare the version
  // If argVersion <= latestDocumented then the latestDocumented version is a revision of the current argVersion
  const latestVersion = semver.gt(argVersion, latestDocumented) ? argVersion : latestDocumented

  console.log(`latestVersion: ${latestVersion}`)
  return callback(null, latestVersion)
}

module.exports = {
  editChangelog: true,
  parseFooterTags: true,
  updateVersion: 'update-version-file',

  addEntryToChangelog: {
    preset: 'prepend',
    fromLine: 6
  },

  includeCommitWhen: (commit) => { return true; },
  getIncrementLevelFromCommit: (commit) => {
    return 'patch'
  },
  incrementVersion: (currentVersion, incrementLevel) => {
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
  },

  template: [
    '## v{{version}} - {{moment date "Y-MM-DD"}}',
    '',
    '{{#each commits}}',
    '{{#if this.author}}',
    '* {{capitalize this.subject}} [{{this.author}}]',
    '{{else}}',
    '* {{capitalize this.subject}}',
    '{{/if}}',
    '{{/each}}'
  ].join('\n')
}
