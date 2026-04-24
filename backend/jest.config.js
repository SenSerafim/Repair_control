module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: '.',
  testRegex: '.*\\.spec\\.ts$',
  transform: {
    '^.+\\.(t|j)s$': 'ts-jest',
  },
  moduleNameMapper: {
    '^@app/common(|/.*)$': '<rootDir>/libs/common/src$1',
    '^@app/rbac(|/.*)$': '<rootDir>/libs/rbac/src$1',
    '^@app/files(|/.*)$': '<rootDir>/libs/files/src$1',
  },
  collectCoverageFrom: [
    'apps/**/*.(t|j)s',
    'libs/**/*.(t|j)s',
    '!**/*.spec.ts',
    '!**/*.module.ts',
    '!**/main.ts',
    '!**/index.ts',
  ],
  coverageDirectory: './coverage',
  testEnvironment: 'node',
  testPathIgnorePatterns: ['/node_modules/', '/dist/'],
};
