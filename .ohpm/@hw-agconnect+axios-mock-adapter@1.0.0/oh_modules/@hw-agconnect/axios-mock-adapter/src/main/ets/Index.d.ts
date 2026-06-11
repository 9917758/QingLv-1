import { AxiosAdapter, AxiosInstance, AxiosRequestConfig } from '@ohos/axios';

export interface AxiosHeaders {
  [key: string]: string | number | boolean | null | undefined;
}

export type MockArrayResponse = [
  status: number,
  data?: any,
  headers?: AxiosHeaders
];

export type MockObjectResponse = {
  status: number;
  data: any;
  headers?: AxiosHeaders,
  config?: AxiosRequestConfig
};

export type MockResponse = MockArrayResponse | MockObjectResponse;

export type CallbackResponseSpecFunc = (
  config: AxiosRequestConfig
) => MockResponse | Promise<MockResponse>;

export type ResponseSpecFunc = <T = any>(
  statusOrCallback: number | CallbackResponseSpecFunc,
  data?: T,
  headers?: AxiosHeaders
) => AxiosMockAdapter;

declare namespace MockAdapter {
  export interface RequestHandler {
    reply: ResponseSpecFunc;
    replyOnce: ResponseSpecFunc;

    withDelayInMs(delay: number): RequestHandler;

    passThrough(): AxiosMockAdapter;

    abortRequest(): AxiosMockAdapter;

    abortRequestOnce(): AxiosMockAdapter;

    networkError(): AxiosMockAdapter;

    networkErrorOnce(): AxiosMockAdapter;

    timeout(): AxiosMockAdapter;

    timeoutOnce(): AxiosMockAdapter;
  }
}

export interface MockAdapterOptions {
  delayResponse?: number;
  onNoMatch?: 'passthrough' | 'throwException';
}

export interface AsymmetricMatcher {
  asymmetricMatch: Function;
}

export interface ParamsMatcher {
  [param: string]: any;
}

export interface HeadersMatcher {
  [header: string]: string;
}

export type UrlMatcher = string | RegExp;

export type AsymmetricParamsMatcher = AsymmetricMatcher | ParamsMatcher;

export type AsymmetricHeadersMatcher = AsymmetricMatcher | HeadersMatcher;

export type AsymmetricRequestDataMatcher = AsymmetricMatcher | any;

export interface ConfigMatcher {
  params?: AsymmetricParamsMatcher;
  headers?: AsymmetricHeadersMatcher;
  data?: AsymmetricRequestDataMatcher;
}

export type RequestMatcherFunc = (
  matcher?: UrlMatcher,
  body?: AsymmetricRequestDataMatcher,
  config?: ConfigMatcher
) => MockAdapter.RequestHandler;

export type NoBodyRequestMatcherFunc = (
  matcher?: UrlMatcher,
  config?: ConfigMatcher
) => MockAdapter.RequestHandler;

export type verb =
  | 'get'
    | 'post'
    | 'put'
    | 'delete'
    | 'patch'
    | 'options'
    | 'head'
    | 'list'
    | 'link'
    | 'unlink';

export type HistoryArray = AxiosRequestConfig[] & Record<verb, AxiosRequestConfig[]>

declare class AxiosMockAdapter {
  static default: typeof AxiosMockAdapter;
  history: HistoryArray;
  onAny: NoBodyRequestMatcherFunc;
  onGet: NoBodyRequestMatcherFunc;
  onDelete: NoBodyRequestMatcherFunc;
  onHead: NoBodyRequestMatcherFunc;
  onOptions: NoBodyRequestMatcherFunc;
  onPost: RequestMatcherFunc;
  onPut: RequestMatcherFunc;
  onPatch: RequestMatcherFunc;
  onList: RequestMatcherFunc;
  onLink: RequestMatcherFunc;
  onUnlink: RequestMatcherFunc;

  constructor(axiosInstance: AxiosInstance, options?: MockAdapterOptions);

  adapter(): AxiosAdapter;

  reset(): void;

  resetHandlers(): void;

  resetHistory(): void;

  restore(): void;
}

export default AxiosMockAdapter