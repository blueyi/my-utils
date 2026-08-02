/**
 * Minimal JSX runtime type stubs for the `react-jsx` transform.
 *
 * The canvas runtime supplies the actual implementation; this declaration
 * lets `"jsx": "react-jsx"` resolve without a full `@types/react`.
 */

/* eslint-disable @typescript-eslint/no-explicit-any */

export namespace JSX {
  type Element = import("./index.js").ReactElement;
  interface IntrinsicElements {
    [tag: string]: any;
  }
}

export function jsx(type: any, props: any, key?: string): JSX.Element;
export function jsxs(type: any, props: any, key?: string): JSX.Element;
