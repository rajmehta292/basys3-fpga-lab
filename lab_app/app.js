/* Basys3 Mastery Lab client. Kept dependency-free so it works with run.py. */

const state = {
  lessons: [],
  completed: new Set(JSON.parse(localStorage.getItem("basys3-completed") || "[]")),
  quizPassed: new Set(JSON.parse(localStorage.getItem("basys3-quiz-passed") || "[]")),
  view: "dashboard",
  selectedLesson: 0,
  switches: 0,
  simMode: "direct",
  health: null,
};

const $ = (id) => document.getElementById(id);
const escapeHtml = (value) => String(value ?? "")
  .replaceAll("&", "&amp;").replaceAll("<", "&lt;")
  .replaceAll(">", "&gt;").replaceAll('"', "&quot;");

function toast(message, tone = "") {
  const node = $("toast");
  node.textContent = message;
  node.className = `toast show ${tone}`;
  window.clearTimeout(toast.timer);
  toast.timer = window.setTimeout(() => { node.className = "toast"; }, 3200);
}

function setView(view) {
  state.view = view;
  document.querySelectorAll(".view").forEach((node) => node.classList.toggle("active", node.id === `view-${view}`));
  document.querySelectorAll(".nav-item").forEach((node) => node.classList.toggle("active", node.dataset.view === view));
  const active = document.querySelector(`#view-${view}`);
  $("current-section").textContent = active?.dataset.title || view;
  if (view === "curriculum") renderCurriculum();
  if (view === "simulator") renderSimulator();
  if (view === "workspace") renderWorkspace();
  if (view === "board") renderBoard();
}

function saveProgress() {
  localStorage.setItem("basys3-completed", JSON.stringify([...state.completed]));
  localStorage.setItem("basys3-quiz-passed", JSON.stringify([...state.quizPassed]));
}

function renderMetrics() {
  const done = state.completed.size;
  const metrics = [
    ["01", "board", "hardware map"],
    ["10", "missions", "guided checkpoints"],
    ["100", "MHz", "onboard clock"],
  ];
  $("dashboard-metrics").innerHTML = metrics.map(([value, unit, label]) =>
    `<div class="metric-card"><strong>${value}</strong><span>${unit}</span><small>${label}</small></div>`).join("");
  $("sidebar-progress-label").textContent = `${done} of ${state.lessons.length || 10} checkpoints`;
  const pct = state.lessons.length ? Math.round((done / state.lessons.length) * 100) : 0;
  const ring = $("progress-ring");
  if (ring) ring.querySelector("span").textContent = `${pct}%`;
}

function renderDashboard() {
  renderMetrics();
  const next = state.lessons.findIndex((lesson) => !state.completed.has(lesson.id));
  const index = next < 0 ? 0 : next;
  const lesson = state.lessons[index];
  if (!lesson) return;
  $("next-lesson-heading").textContent = lesson.title;
  $("next-lesson-card").innerHTML = `
    <div class="next-lesson-copy"><span class="eyebrow">Mission ${String(lesson.number).padStart(2, "0")} · ${escapeHtml(lesson.phase)}</span>
    <h3>${escapeHtml(lesson.tagline)}</h3><p>${escapeHtml(lesson.goal)}</p></div>
    <button class="primary-button" data-lesson-start="${index}">Open mission <span>→</span></button>`;
  $("board-snapshot").innerHTML = `
    <div class="snapshot-fact"><strong>XC7A35T</strong><span>Artix-7 FPGA</span></div>
    <div class="snapshot-fact"><strong>100 MHz</strong><span>clock on W5</span></div>
    <div class="snapshot-fact"><strong>16 + 16</strong><span>switches and LEDs</span></div>`;
  document.querySelectorAll("[data-lesson-start]").forEach((node) => node.addEventListener("click", () => {
    state.selectedLesson = Number(node.dataset.lessonStart);
    setView("curriculum");
  }));
}

function renderCurriculum() {
  $("lesson-list").innerHTML = state.lessons.map((lesson, index) => {
    const done = state.completed.has(lesson.id);
    return `<button class="lesson-item ${index === state.selectedLesson ? "selected" : ""} ${done ? "complete" : ""}" data-lesson="${index}">
      <span class="lesson-number">${String(lesson.number).padStart(2, "0")}</span><span><small>${escapeHtml(lesson.phase)}</small><strong>${escapeHtml(lesson.title)}</strong></span><i>${done ? "✓" : "→"}</i></button>`;
  }).join("");
  document.querySelectorAll("[data-lesson]").forEach((node) => node.addEventListener("click", () => {
    state.selectedLesson = Number(node.dataset.lesson);
    renderCurriculum();
  }));
  const lesson = state.lessons[state.selectedLesson];
  if (!lesson) return;
  const done = state.completed.has(lesson.id);
  $("lesson-detail").innerHTML = `
    <span class="eyebrow accent-eyebrow">Mission ${String(lesson.number).padStart(2, "0")} · ${escapeHtml(lesson.phase)}</span>
    <h2>${escapeHtml(lesson.title)}</h2><p class="lesson-tagline">${escapeHtml(lesson.tagline)}</p>
    <div class="detail-block"><span class="eyebrow">Goal</span><p>${escapeHtml(lesson.goal)}</p></div>
    <div class="detail-block"><span class="eyebrow">Understand</span><p>${escapeHtml(lesson.concept)}</p><p class="why-note">Why it matters: ${escapeHtml(lesson.why)}</p></div>
    <div class="detail-block"><span class="eyebrow">Checklist</span><ul>${lesson.checklist.map((item) => `<li>${escapeHtml(item)}</li>`).join("")}</ul></div>
    <div class="detail-block hands-on-block"><span class="eyebrow">Do this with your hands</span><p>${escapeHtml(lesson.experiment)}</p></div>
    <div class="code-card"><span class="eyebrow">Try this</span><pre>${escapeHtml(lesson.code)}</pre></div>
    <div class="challenge-card"><span class="eyebrow">Challenge</span><p>${escapeHtml(lesson.challenge)}</p><details><summary>Reveal answer</summary><p>${escapeHtml(lesson.answer)}</p></details></div>
    <div class="detail-block quiz-block"><span class="eyebrow">Checkpoint question</span><p><strong>${escapeHtml(lesson.quiz.question)}</strong></p><div class="lesson-quiz-options">${lesson.quiz.options.map((option, index) => `<button data-quiz-answer="${index}">${escapeHtml(option)}</button>`).join("")}</div><div id="lesson-quiz-feedback" class="quiz-feedback">${state.quizPassed.has(lesson.id) ? "Passed. Now explain the idea in your own words." : ""}</div></div>
    <button class="primary-button" id="complete-lesson">${done ? "Checkpoint complete ✓" : "Mark checkpoint complete"} <span>→</span></button>`;
  $("complete-lesson").addEventListener("click", () => {
    if (done) state.completed.delete(lesson.id); else state.completed.add(lesson.id);
    saveProgress(); renderCurriculum(); renderDashboard();
    toast(done ? "Checkpoint reopened." : "Checkpoint saved. Keep going.", "success");
  });
  document.querySelectorAll("[data-quiz-answer]").forEach((node) => node.addEventListener("click", () => {
    const feedback = $("lesson-quiz-feedback");
    if (Number(node.dataset.quizAnswer) === lesson.quiz.correct) {
      state.quizPassed.add(lesson.id); saveProgress(); feedback.textContent = "Correct. Put the idea into your own words, then mark the checkpoint complete."; feedback.className = "quiz-feedback good";
    } else {
      feedback.textContent = "Not quite. Re-read the Understand box and try again—the explanation matters more than the score."; feedback.className = "quiz-feedback retry";
    }
  }));
  renderMetrics();
}

function ledBits(value) {
  return Array.from({ length: 16 }, (_, i) => `<span class="sandbox-led ${value & (1 << i) ? "on" : ""}"></span>`).join("");
}

function simResult(value) {
  const sw = state.switches & 0xffff;
  switch (state.simMode) {
    case "and": return (sw & 1) && ((sw >> 1) & 1) ? 1 : 0;
    case "or": return ((sw & 1) | ((sw >> 1) & 1)) ? 1 : 0;
    case "xor": return ((sw & 1) ^ ((sw >> 1) & 1)) ? 1 : 0;
    case "invert": return (~sw) & 0xff;
    case "replicate": return (sw & 1) ? 0xffff : 0;
    case "mux": return (sw & 0x8000) ? (~sw & 0xff) : (sw & 0xff);
    default: return sw;
  }
}

function simCode() {
  const code = {
    direct: "assign led = sw;",
    and: "assign led[0] = sw[0] & sw[1];",
    or: "assign led[0] = sw[0] | sw[1];",
    xor: "assign led[0] = sw[0] ^ sw[1];",
    invert: "assign led[7:0] = ~sw[7:0];",
    replicate: "assign led = {16{sw[0]}};",
    mux: "assign led[7:0] = sw[15] ? ~sw[7:0] : sw[7:0];",
  };
  return code[state.simMode];
}

function renderSimulator() {
  const grid = $("switch-grid");
  grid.innerHTML = Array.from({ length: 16 }, (_, i) => `<button class="sandbox-switch ${state.switches & (1 << i) ? "on" : ""}" data-switch="${i}">SW${i}<b>${state.switches & (1 << i) ? 1 : 0}</b></button>`).join("");
  grid.querySelectorAll("[data-switch]").forEach((node) => node.addEventListener("click", () => {
    state.switches ^= 1 << Number(node.dataset.switch); renderSimulator();
  }));
  const output = simResult();
  $("signal-visual").innerHTML = `<div class="signal-box">SW <b>${state.switches.toString(16).toUpperCase().padStart(4, "0")}</b></div><div class="signal-arrow">→</div><div class="signal-box output-box">LED <b>${output.toString(16).toUpperCase().padStart(4, "0")}</b></div>`;
  $("sim-readout").innerHTML = `<div class="led-strip">${ledBits(output)}</div><p>input <strong>0x${state.switches.toString(16).toUpperCase().padStart(4, "0")}</strong> → output <strong>0x${output.toString(16).toUpperCase().padStart(4, "0")}</strong></p>`;
  $("sim-code").textContent = simCode();
  $("sim-explanation").textContent = "Flip a switch and watch the software model update. The same relationship becomes LUTs and routing after synthesis.";
}

function renderWorkspace() {
  const editor = $("verilog-editor");
  if (!editor.value) editor.value = `module basys3_hello(input wire [15:0] sw, output wire [15:0] led);\n  assign led = sw;\nendmodule\n`;
  $("char-count").textContent = `${editor.value.length} chars`;
}

function analyzeCode() {
  const code = $("verilog-editor").value;
  const findings = [];
  if (!/module\s+\w+/.test(code)) findings.push(["warn", "No module declaration found."]);
  if (/assign\s+\w+\s*=/.test(code)) findings.push(["good", "Continuous assignment detected: this describes combinational hardware."]);
  if (/always\s*\@\s*\(\s*posedge/.test(code)) findings.push(["good", "Clocked logic detected: registers update on a rising edge."]);
  if (!/endmodule/.test(code)) findings.push(["warn", "The module is missing `endmodule`."]);
  if (!findings.length) findings.push(["note", "The guided checker found no obvious pattern; use Vivado or a simulator for authoritative analysis."]);
  $("analysis-state").textContent = "analyzed";
  $("analysis-results").innerHTML = findings.map(([tone, message]) => `<div class="analysis-row ${tone}"><b>${tone}</b><span>${escapeHtml(message)}</span></div>`).join("");
  $("terminal-output").insertAdjacentHTML("beforeend", `<div><span class="terminal-prompt">lab</span> analyzed ${code.length} characters</div>`);
}

async function realSimulation() {
  const result = await postAction({ action: "simulate_with_iverilog", code: $("verilog-editor").value });
  if (result.available === false) toast("iverilog is not installed on this host; guided analysis is still available.", "warn");
  else toast(result.ok ? "iverilog simulation completed." : `Simulation ${result.stage || "failed"}.`, result.ok ? "success" : "warn");
  if (result.output) $("terminal-output").insertAdjacentHTML("beforeend", `<div><span class="terminal-prompt">iverilog</span> ${escapeHtml(result.output)}</div>`);
}

const components = {
  clock: ["100 MHz clock", "Input · W5", "The single onboard oscillator is the timing reference for synchronous logic. Constrain it to a 10 ns period and derive slower enables with counters rather than making arbitrary signals into clocks."],
  switches: ["16 slide switches", "Inputs · V17 → R2", "Each switch is a steady logic-level input. Use them for visible truth tables, but synchronize/debounce them before using them as control events."],
  leds: ["16 user LEDs", "Outputs · U16 → L1", "The LEDs are ideal for smoke tests: prove that a bitstream reached the FPGA and that the XDC mapping is correct."],
  display: ["Four-digit seven-segment", "Outputs · active-low", "The four digits share CA..CG/DP. Scan one active-low anode at a time and drive the shared active-low cathode pattern."],
  buttons: ["Five pushbuttons", "Inputs · active-high", "Buttons are mechanical and bounce. Synchronize, debounce, and edge-detect them; never use a raw button as a clock."],
  pmod: ["Digital Pmods JA/JB/JC", "3.3 V expansion", "Each port exposes eight FPGA signals plus 3.3 V and ground. Check direction, voltage, current, and timing before connecting a peripheral."],
  vga: ["VGA output", "12-bit RGB + sync", "A common first mode is 640×480 at 60 Hz with a 25 MHz pixel clock generated from the 100 MHz source."],
};

function renderBoard(component = "clock") {
  const [title, meta, body] = components[component] || components.clock;
  $("component-detail").innerHTML = `<span class="eyebrow">Board component</span><h2>${title}</h2><strong class="component-meta">${meta}</strong><p>${body}</p><div class="next-experiment"><span class="eyebrow">Next experiment</span><p>Find this signal in the XDC, trace it into the top module, and make its behavior observable on an LED or in simulation.</p></div>`;
  $("board-status-card").innerHTML = state.health ? `<span class="status-dot ${state.health.usb?.boardCandidate ? "good" : "bad"}"></span><strong>${state.health.usb?.boardCandidate ? "USB board detected" : "Board not detected"}</strong><small>${state.health.serialPorts?.length || 0} serial node(s) · ${state.health.tools?.vivado_lab?.found ? "Vivado Lab found" : "programmer unavailable"}</small>` : "Checking hardware…";
  document.querySelectorAll("[data-component]").forEach((node) => node.onclick = () => renderBoard(node.dataset.component));
}

async function postAction(payload) {
  const response = await fetch("/api/actions", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) });
  return response.json();
}

async function refreshHealth() {
  try {
    state.health = await (await fetch("/api/health", { cache: "no-store" })).json();
    const present = state.health.usb?.boardCandidate;
    $("connection-label").textContent = present ? "USB board detected" : "Board not detected";
    $("connection-pill").classList.toggle("connected", present);
    $("sidebar-status-text").textContent = present ? "USB link visible" : "No board detected";
    $("sidebar-status-dot").classList.toggle("good", present);
    if (state.view === "board") renderBoard();
  } catch (error) {
    toast(`Diagnostics unavailable: ${error.message}`, "warn");
  }
}

async function generateProject() {
  const name = $("project-name").value || "my-first-led-lab";
  const result = await postAction({ action: "generate_starter", name });
  $("hardware-action-result").textContent = result.ok ? `Generated ${result.path}` : result.error;
  if (result.ok) toast("Starter project generated.", "success");
}

async function programBoard() {
  const result = await postAction({ action: "program_board", bitstream: $("bitstream-path").value });
  $("hardware-action-result").textContent = result.ok ? "Programming completed." : (result.error || result.output || "Programming failed.");
  toast(result.ok ? "Programming completed." : "Programming did not complete; read the result panel.", result.ok ? "success" : "warn");
}

async function init() {
  try { state.lessons = await (await fetch("/api/curriculum")).json(); } catch (error) { toast(`Curriculum unavailable: ${error.message}`, "warn"); }
  document.querySelectorAll("[data-view]").forEach((node) => node.addEventListener("click", () => setView(node.dataset.view)));
  document.querySelectorAll("[data-view-target]").forEach((node) => node.addEventListener("click", () => setView(node.dataset.viewTarget)));
  $("continue-button").onclick = () => { const next = state.lessons.findIndex((lesson) => !state.completed.has(lesson.id)); state.selectedLesson = next < 0 ? 0 : next; setView("curriculum"); };
  $("help-button").onclick = () => toast("Start with Mission 1, then make every signal path visible before adding complexity.");
  $("refresh-health").onclick = refreshHealth;
  $("sim-mode").onchange = (event) => { state.simMode = event.target.value; renderSimulator(); };
  $("sim-answers").onclick = (event) => { if (event.target.matches("button")) $("sim-feedback").textContent = event.target.dataset.answer === "led" ? "Correct: the LED output changes first; the package pin mapping does not." : "Not this time—flip an input and follow the combinational path."; };
  $("verilog-editor").oninput = (event) => { $("char-count").textContent = `${event.target.value.length} chars`; };
  $("analyze-code").onclick = analyzeCode;
  $("reset-code").onclick = () => { $("verilog-editor").value = ""; renderWorkspace(); };
  $("real-sim-button").onclick = realSimulation;
  $("clear-journal").onclick = () => { $("terminal-output").innerHTML = ""; };
  $("generate-project").onclick = generateProject;
  $("program-board").onclick = programBoard;
  renderDashboard(); renderCurriculum(); renderSimulator(); renderWorkspace(); renderBoard();
  await refreshHealth();
}

init();
