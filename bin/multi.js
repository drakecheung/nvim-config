#!/usr/bin/env node

// sudo npm install -g ramda colors yaml node-pty
// NODE_PATH=$(npm root -g) .devbase/bin/multi.js

const {spawn} = require("node-pty");
const R = require("ramda");
const colors = require("colors");
const fs = require("fs");
const YAML = require("yaml");

colors.enable()

const colorFn = [
  colors.brightRed,
  colors.brightGreen,
  colors.brightYellow,
  colors.brightBlue,
  colors.brightMagenta,
  colors.brightCyan,
  colors.brightWhite,
  colors.red,
  colors.green,
  colors.yellow,
  colors.blue,
  colors.magenta,
  colors.cyan,
  colors.white,
  colors.gray,
  colors.grey,
];

const spawnP = (cli, options, fn) =>
  new Promise((resolve, reject) => {
    const proc = spawn("bash", ["-c", cli]);

    proc.on('data', (data) => {
      fn(`${data}`);
    });

    proc.on('exit', (code) => {
      resolve(code === 0);
    });
  });

/* eslint-disable fp/no-loops */
/* eslint-disable no-restricted-syntax */
/* eslint-disable guard-for-in */
const printLines = (tag, lines) => {
  const lls = R.compose(
    R.map(line => `${tag}${line}`),
    R.split("\n"),
    R.trim,
  )(lines);
  for (const line of lls) {
    console.log(line);
  }
};

const filepath = process.argv[2];
if (!fs.existsSync(filepath)) {
  console.log(`${filepath} do not exists.`);
  process.exit();
}
const tasks = YAML.parse(fs.readFileSync(filepath).toString());

const tagMaxLen = R.compose(
  R.apply(Math.max),
  R.map(R.length),
  R.pluck("tag"),
)(tasks);

const sep = " | ".gray

/* eslint-disable fp/no-loops */
/* eslint-disable no-restricted-syntax */
for (const [idx, task] of tasks.entries()) {
  task.display = colorFn[idx](task.tag.padEnd(tagMaxLen, " ")) + sep;
  task.state = "pending";
}

const findTask = tag => R.find(R.propEq(tag, "tag"), tasks);

// validate all after tag exists
for (const task of tasks) {
  for (const afterTag of task.after || []) {
    if (!findTask(afterTag)) {
      console.error(`${task.tag} depends on ${afterTag} which doesn't exists.`);
      process.exit(1);
    }
  }
}

const runAllRunnable = () => {
  R.map(
    async (task) => {
      if (task.state !== "pending") {
        return false;
      }
      const states = R.map((afterTag) => findTask(afterTag).state, task.after || []);
      if (R.any(R.equals("failed"), states)) {
        task.state = "skipped";
        printLines(task.display, "- skipped -".gray);
        return false;
      }
      if (!R.all(R.equals("completed"), states)) return false;

      task.state = "running";
      const isSucceeded = await spawnP(task.cmd.replaceAll("\n", ""), {}, (lines) => {
        printLines(task.display, lines);
      })
      if (isSucceeded) {
        task.state = "completed";
        printLines(task.display, "- completed -".gray);
      } else {
        task.state = "failed";
        printLines(task.display, "- failed -".gray);
      }
      runAllRunnable();
    }
  )(tasks);
};

runAllRunnable();
