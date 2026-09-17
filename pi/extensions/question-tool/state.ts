export interface QuestionOption {
	label: string;
	description?: string;
}

export interface QuestionSpec {
	question: string;
	header: string;
	options: QuestionOption[];
	multiple?: boolean;
}

export interface State {
	tab: number;
	cursor: number;
	selected: Set<number>[];
	custom: (string | null)[];
	editing: boolean;
	submitted: boolean;
}

export type Action =
	| { type: "cursor"; delta: number }
	| { type: "tab"; delta: number }
	| { type: "tabTo"; index: number }
	| { type: "choose"; index?: number }
	| { type: "custom"; text: string }
	| { type: "cancelEdit" };

/** Index of the synthetic "Type your own answer" row, always last. */
export function customRow(question: QuestionSpec): number {
	return question.options.length;
}

export function isConfirmTab(state: State, questions: QuestionSpec[]): boolean {
	return questions.length > 1 && state.tab === questions.length;
}

function lastTab(questions: QuestionSpec[]): number {
	return questions.length > 1 ? questions.length : 0;
}

function clamp(value: number, max: number): number {
	return Math.min(Math.max(value, 0), max);
}

export function createState(questions: QuestionSpec[]): State {
	return {
		tab: 0,
		cursor: 0,
		selected: questions.map(() => new Set<number>()),
		custom: questions.map(() => null),
		editing: false,
		submitted: false,
	};
}

/** One list of chosen labels per question, empty when unanswered. */
export function answersOf(state: State, questions: QuestionSpec[]): string[][] {
	return questions.map((question, i) => {
		const custom = state.custom[i];
		if (custom) return [custom];
		return question.options.filter((_, index) => state.selected[i].has(index)).map((option) => option.label);
	});
}

export function reduce(state: State, action: Action, questions: QuestionSpec[]): State {
	switch (action.type) {
		case "cursor": {
			if (isConfirmTab(state, questions)) return state;
			const max = customRow(questions[state.tab]);
			return { ...state, cursor: clamp(state.cursor + action.delta, max) };
		}
		case "tab":
			return { ...state, tab: clamp(state.tab + action.delta, lastTab(questions)), cursor: 0 };

		case "tabTo":
			return { ...state, tab: clamp(action.index, lastTab(questions)), cursor: 0 };

		case "choose": {
			if (isConfirmTab(state, questions)) return { ...state, submitted: true };

			const question = questions[state.tab];
			const index = action.index ?? state.cursor;
			if (index === customRow(question)) return { ...state, cursor: index, editing: true };

			const selected = state.selected.map((set, i) => (i === state.tab ? new Set(set) : set));
			if (question.multiple) {
				if (!selected[state.tab].delete(index)) selected[state.tab].add(index);
				return { ...state, cursor: index, selected };
			}
			selected[state.tab] = new Set([index]);
			return advance({ ...state, cursor: index, selected, custom: replace(state.custom, state.tab, null) }, questions);
		}

		case "custom": {
			const selected = state.selected.map((set, i) => (i === state.tab ? new Set<number>() : set));
			const custom = replace(state.custom, state.tab, action.text);
			return advance({ ...state, selected, custom, editing: false }, questions);
		}

		case "cancelEdit":
			return { ...state, editing: false };
	}
}

function replace<T>(values: T[], index: number, value: T): T[] {
	return values.map((existing, i) => (i === index ? value : existing));
}

/** Single-select answers move on by themselves: to the next question, or straight out. */
function advance(state: State, questions: QuestionSpec[]): State {
	if (questions.length === 1) return { ...state, submitted: true };
	return { ...state, tab: clamp(state.tab + 1, lastTab(questions)), cursor: 0 };
}
