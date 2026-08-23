// Deliver a folder of RFC 822 files to MailDev over SMTP.
//
// MailDev's own API only reads; the way anything gets into MailDev is the way an
// application under test puts it there, which is a plain SMTP conversation on
// port 1025. Node is what this image is, and net is in Node, so nothing is
// installed to do it.
const fs = require("fs");
const net = require("net");
const path = require("path");

const dir = process.argv[2];
const port = Number(process.argv[3] || 1025);

function addresses(header, raw) {
  const line = new RegExp("^" + header + ":(.*)$", "im").exec(raw);
  if (!line) return [];
  return (line[1].match(/[^\s<>,"]+@[^\s<>,"]+/g) || []);
}

function send(file) {
  return new Promise((resolve) => {
    const raw = fs.readFileSync(file, "utf8").replace(/\r?\n/g, "\r\n");
    const from = addresses("From", raw)[0];
    const to = addresses("To", raw);
    if (!from || to.length === 0) return resolve(false);

    // Dot-stuffing: a line that is a single dot ends DATA, so any body line
    // starting with one gets another.
    const body = raw.replace(/^\./gm, "..");
    const script = ["EHLO droplive", `MAIL FROM:<${from}>`]
      .concat(to.map((address) => `RCPT TO:<${address}>`))
      .concat(["DATA", body + "\r\n.", "QUIT"]);

    const socket = net.createConnection({ host: "127.0.0.1", port });
    let step = -1;
    let buffered = "";
    socket.setEncoding("utf8");
    socket.setTimeout(15000, () => { socket.destroy(); resolve(false); });
    socket.on("error", () => resolve(false));
    socket.on("close", () => resolve(step >= script.length - 1));
    socket.on("data", (chunk) => {
      buffered += chunk;
      // A reply ends on a line whose code is followed by a space, not a hyphen.
      if (!/^\d{3} .*\r\n$/m.test(buffered.split(/(?<=\r\n)/).pop() || "")) return;
      if (buffered.startsWith("4") || buffered.startsWith("5")) {
        socket.destroy();
        return resolve(false);
      }
      buffered = "";
      step += 1;
      if (step < script.length) socket.write(script[step] + "\r\n");
    });
  });
}

(async () => {
  const files = fs.readdirSync(dir).filter((f) => f.endsWith(".eml")).sort();
  let sent = 0;
  for (const file of files) {
    if (await send(path.join(dir, file))) sent += 1;
  }
  console.error(`[droplive] delivered ${sent} of ${files.length} messages`);
})();
