/**
 * ctx.ui.setStatus keys shared across extensions, kept dependency-free so
 * importers (eg. context-bar) don't pull in heavier modules — permission's
 * tree-sitter-based bash parser, in particular — just for a string constant.
 */
export const PLAN_MODE_STATUS_KEY = "plan-mode";
export const APPROVE_STATUS_KEY = "approve";
