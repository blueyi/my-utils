/**
 * Minimal React type stubs for canvas files.
 *
 * The canvas runtime provides React at execution time; these declarations
 * give TypeScript enough surface to type-check `.canvas.tsx` JSX without
 * shipping the full `@types/react` package into the canvases directory.
 */

/* eslint-disable @typescript-eslint/no-explicit-any */

export type ReactNode =
  | string
  | number
  | boolean
  | null
  | undefined
  | ReactElement
  | ReactNode[];

export interface ReactElement {
  type: any;
  props: any;
  key: string | null;
}

export type JSX = {
  Element: ReactElement;
  IntrinsicElements: {
    [tag: string]: any;
  };
};

export type CSSProperties = Record<string, any>;

export type RefObject<T> = { readonly current: T | null };

export type Dispatch<A> = (value: A) => void;
export type SetStateAction<S> = S | ((prevState: S) => S);

export function useState<S>(initialState: S | (() => S)): [S, Dispatch<SetStateAction<S>>];
export function useEffect(effect: () => (void | (() => void)), deps?: readonly any[]): void;
export function useCallback<T extends (...args: any[]) => any>(callback: T, deps: readonly any[]): T;
export function useMemo<T>(factory: () => T, deps: readonly any[]): T;
export function useRef<T>(initialValue: T): { current: T };
export function useRef<T>(initialValue: T | null): RefObject<T>;
