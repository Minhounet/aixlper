# Documents screen: checks

Each acceptance criterion has one standalone Node/Playwright script under
`checks/`, named after it (`ac<n>-<what>.js`), printing one result line
`[AC<n>] PASS` or `[AC<n>] FAIL: <reason>` and exiting non-zero on failure.
`checks/ac0-page-title.js` is the model to follow.

Run one: `BASE_URL=<base url> node checks/<file>.js`
