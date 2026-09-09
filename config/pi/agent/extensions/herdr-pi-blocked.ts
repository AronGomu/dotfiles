// Custom sidecar for herdr pi integration.
// Stock herdr-agent-state.ts listens for herdr:blocked but never emits it for
// pi ask/approval/UI dialogs. This fills that gap without editing the managed file.
// @ts-nocheck

const HERDR_ENV = process.env.HERDR_ENV;

function enabled() {
  return HERDR_ENV === "1";
}

function askBlockedMessage(args) {
  const questions = Array.isArray(args?.questions) ? args.questions : [];
  const first = questions.find((q) => typeof q?.question === "string");
  if (first?.question) return first.question;
  if (typeof args?.question === "string") return args.question;
  if (typeof args?.prompt === "string") return args.prompt;
  if (typeof args?.message === "string") return args.message;
  return "waiting for user input";
}

/** Tools that block on explicit user input (not generic bash/read/etc). */
const INPUT_TOOLS = new Set(["ask", "questionnaire", "ask_user", "AskUserQuestion"]);

export default function (pi) {
  if (!enabled()) {
    return;
  }

  let dialogDepth = 0;
  let uiWrapped = false;

  function setBlocked(active, label) {
    pi.events.emit("herdr:blocked", { active: !!active, label });
  }

  function pushDialog(label) {
    dialogDepth += 1;
    if (dialogDepth === 1) {
      setBlocked(true, label || "waiting for user input");
    }
  }

  function popDialog() {
    if (dialogDepth <= 0) return;
    dialogDepth -= 1;
    if (dialogDepth === 0) {
      setBlocked(false);
    }
  }

  function wrapUi(ui) {
    if (!ui || uiWrapped) return;
    uiWrapped = true;

    const wrap = (method, labelFromArgs) => {
      const original = ui[method];
      if (typeof original !== "function") return;
      ui[method] = async function wrappedUiMethod(...args) {
        pushDialog(labelFromArgs(...args));
        try {
          return await original.apply(ui, args);
        } finally {
          popDialog();
        }
      };
    };

    wrap("confirm", (title, message) =>
      typeof title === "string" && title
        ? title
        : typeof message === "string" && message
          ? message
          : "confirmation required",
    );
    wrap("select", (title) =>
      typeof title === "string" && title ? title : "selection required",
    );
    wrap("input", (title) =>
      typeof title === "string" && title ? title : "input required",
    );
    wrap("custom", () => "waiting for user input");
  }

  // session_start fires for startup/reload/new/resume/fork (session_switch removed).
  pi.on("session_start", (_event, ctx) => {
    uiWrapped = false;
    dialogDepth = 0;
    if (ctx?.hasUI === true) {
      wrapUi(ctx.ui);
    }
  });

  pi.on("tool_execution_start", (event) => {
    if (!INPUT_TOOLS.has(event?.toolName)) return;
    setBlocked(true, askBlockedMessage(event.args));
  });

  pi.on("tool_execution_end", (event) => {
    if (!INPUT_TOOLS.has(event?.toolName)) return;
    setBlocked(false);
  });

  // Harmless no-op on stock pi 0.80 (event never emitted). Kept for OMP-like builds.
  pi.on("tool_approval_requested", (event) => {
    const label = event?.reason || `${event?.toolName || "Tool"} approval`;
    setBlocked(true, label);
  });

  pi.on("tool_approval_resolved", () => {
    setBlocked(false);
  });
}
