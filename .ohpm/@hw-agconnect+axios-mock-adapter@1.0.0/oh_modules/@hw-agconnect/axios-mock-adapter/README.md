# axios-mock-adapter

## 目录

- [简介](#简介)
- [下载安装](#下载安装)
- [使用示例](#使用示例)
- [约束与限制](#约束与限制)

## 简介

Axios adapter 能够轻松模拟请求。本库基于axios-mock-adapter 原库v2.10.0版本进行适配，使其可以运行在
OpenHarmony，并沿用其现有用法和特性。

## 下载安装
`ohpm install @ohos/axios`
`ohpm install @hw-agconnect/axios-mock-adapter`

## 使用示例

### 模拟 `GET` 请求

```typescript
import axios, { AxiosResponse } from '@ohos/axios';
import AxiosMockAdapter from '@hw-agconnect/axios-mock-adapter';

// 为默认实例设置模拟适配器
const mock = new AxiosMockAdapter(axios);

// 模拟所有到 /users 的 GET 请求
// reply 的参数为 (状态码, 数据, 响应头)
interface User {
  id: number;
  name: string;
}

const users: User[] = [{ id: 1, name: "John Smith" }]
mock.onGet("/users").reply(200, users);

axios.get("/users").then((response: AxiosResponse) => {
  console.log(response.data);
});
```

### 模拟带特定参数的 `GET` 请求

```typescript
import axios from '@ohos/axios';
import AxiosMockAdapter from '@hw-agconnect/axios-mock-adapter';

// 为默认实例设置模拟适配器
const mock = new AxiosMockAdapter(axios);

// 当参数 `searchText` 为 'John' 时，模拟到 /users 的 GET 请求
// reply 的参数为 (状态码, 数据, 响应头)
interface User {
  id: number;
  name: string;
}
interface Response {
  users: User[]
}
const users: User[] = [{ id: 1, name: "John Smith" }];
const resp: Response = { users }
mock.onGet("/users", { params: { searchText: "John" } }).reply(200, resp);

axios
  .get("/users", { params: { searchText: "John" } })
  .then((response: AxiosResponse) => {
    console.log(response.data);
  });
```

使用 `params` 时，必须匹配传递给该选项的所有键值对。

### 为响应添加延迟

实例化适配器时指定延迟时间（毫秒），可为响应添加延迟：

```typescript
// 使用此实例的所有请求都将有 2 秒延迟：
const mock = new AxiosMockAdapter(axiosInstance, { delayResponse: 2000 });
```

### 恢复原始适配器

使用 `restore` 移除模拟功能：

```typescript
mock.restore();
```

### 重置已注册的模拟处理器

使用 `resetHandlers` 重置已注册的模拟处理器：

```typescript
mock.resetHandlers();
```

### 重置处理器和历史记录

使用 `reset` 同时重置已注册的模拟处理器和历史记录项：

```typescript
mock.reset();
```

`reset`  与 `restore`  的区别在于：`restore`  会完全从 axios 实例中移除模拟功能，而 `reset` 仅移除通过 onGet、onPost
等添加的所有模拟处理器，但保留模拟功能。

### 模拟低级网络错误

```typescript
// 返回一个失败的 Promise，错误信息为 Error('Network Error')
mock.onGet("/users").networkError();

// networkErrorOnce 可用于仅模拟一次网络错误
mock.onGet("/users").networkErrorOnce();
```

### 模拟网络超时

```typescript
// 返回一个失败的 Promise，错误代码为 'ECONNABORTED'
mock.onGet("/users").timeout();

// timeoutOnce 可用于仅模拟一次超时
mock.onGet("/users").timeoutOnce();
```

### 向 `reply` 传递函数

```typescript
mock.onGet("/users").reply((config: AxiosRequestConfig) => {
  // `config` 是 axios 配置，包含 url 等信息

  // 返回 [状态码, 数据, 响应头] 形式的数组
  return [
    200,
    {
      users: [{ id: 1, name: "John Smith" }],
    },
  ];
});
```

### 向 `reply` 传递返回 axios 请求的函数（模拟重定向）

```typescript
mock.onPost("/foo").reply((config: AxiosRequestConfig) => {
  return axios.get("/bar");
});
```

### 使用正则表达式

```typescript
mock.onGet(/\/users\/\d+/).reply((config: AxiosRequestConfig) => {
  // 可从 config.url 中获取实际的 id

  return [200, {}];
});
```

### 在正则中使用变量

```typescript
const usersUri = "/users";
const url = new RegExp(`${usersUri}/*`);

mock.onGet(url).reply(200, users);
```

### 仅按请求方法匹配（不指定路径）

```typescript
// 模拟所有 POST 请求，返回 HTTP 500
mock.onPost().reply(500);
```

### 支持链式调用

```typescript
mock.onGet("/users").reply(200, users).onGet("/posts").reply(200, posts);
```

### 使用 `.replyOnce()` 仅模拟一次响应

```typescript
mock
  .onGet("/users")
  .replyOnce(200, users) // 第一次请求 /users 后，此处理器会被移除
  .onGet("/users")
  .replyOnce(500); // 第二次请求 /users 会返回状态码 500
// 后续任何请求都会返回 404，因为没有匹配的处理器了
```

### 模拟对特定 URL 的任意请求

```typescript
// 模拟对 /foo 的 GET、POST 等所有请求
mock.onAny("/foo").reply(200);
```

### 使用 `.onAny` 测试请求顺序

```typescript
// 预期的请求顺序：
interface RequestMatch {
  url: string;
  method: string;
  code: number;
  response: ESObject;
}

const responses: RequestMatch [] = [
  {
    method: "GET",
    url: "/foo",
    code: 200,
    response: { foo: "bar" }
  },
  {
    method: "POST",
    url: "/bar",
    code: 200,
    response: { foo: "bar" }
  },
  {
    method: "PUT",
    url: "/baz",
    code: 200,
    response: { foo: "bar" }
  },
];

// 匹配所有请求
mock.onAny().reply((config: AxiosRequestConfig) => {
  const match = responses.shift()!!;
  if (match && config.url === match.url && config.method!!.toUpperCase() === match.method) {
    return [match.code, match.response];
  }
  // 非预期请求，返回错误
  return [500, {}];
});
```

未映射到模拟处理器的请求会被拒绝，并返回 HTTP 404 响应。由于处理器按顺序匹配，可使用最后的 `onAny()` 更改默认行为：

```typescript
// 模拟对 /foo 的 GET 请求，其他所有请求都返回 HTTP 500
mock.onGet("/foo").reply(200).onAny().reply(500);
```

### 模拟带特定请求体 / 数据的请求

```typescript
mock.onPut("/product", { id: 4, name: "foo" }).reply(204);
```

### 使用自定义非对称匹配器（任何带有 `asymmetricMatch` 属性的对象）

```typescript
mock
  .onPost("/product", {
    asymmetricMatch: function (actual) {
      return ["computer", "phone"].includes(actual["type"]);
    },
  })
  .reply(204);
```

### 使用 `.passThrough()` 转发匹配的请求到网络

```typescript
// 模拟对 /api 的 POST 请求返回 HTTP 201，但转发 GET 请求到服务器
mock
  .onPost(/^\/api/)
  .reply(201)
  .onGet(/^\/api/)
  .passThrough();
```

注意处理器的顺序很重要：

```typescript
// 模拟特定请求，未匹配的请求转发
mock
  .onGet("/foo")
  .reply(200)
  .onPut("/bar", { xyz: "abc" })
  .reply(204)
  .onAny()
  .passThrough();
```

注意 `passThrough` 请求不受  `delayResponse` 延迟影响。

### 设置默认转发行为

如果将 `onNoMatch` 选项设置为 `passthrough`，所有请求默认都会转发到网络：

```typescript
// 模拟所有到 /foo 的请求返回 HTTP 200，其他请求转发到服务器
const mock = new AxiosMockAdapter(axiosInstance, { onNoMatch: "passthrough" });

mock.onAny("/foo").reply(200);
```

### 使用 `throwException` 调试未匹配的请求

使用 `onNoMatch` 选项的 `throwException` 模式，当请求未匹配任何处理器时会抛出异常，有助于调试测试模拟：

```typescript
const mock = new AxiosMockAdapter(axiosInstance, { onNoMatch: "throwException" });

mock.onAny("/foo").reply(200);

axios.get("/unexistent-path");

// Exception message on console:
//
// Could not find mock for: 
// {
//   "method": "get",
//   "url": "http://localhost/unexistent-path"
// }
```

### `reply` 函数返回 Promise

```typescript
mock.onGet("/product").reply(() => {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (Math.random() > 0.1) {
        resolve([200, { id: 4, name: "foo" }]);
      } else {
        // reject() 的原因会原样传递。
        // 使用 HTTP 错误状态码模拟服务器故障。
        resolve([500, { success: false }]);
      }
    }, 1000);
  });
});
```

## 历史记录

`history` 属性允许枚举已存在的 axios 请求对象。该属性是一个对象，其键为请求方法，值为请求对象数组。

这在测试中非常有用：

```typescript
describe("Feature", () => {
  it("requests an endpoint", (done) => {
    instance = axios.create();
    mock = new AxiosMockAdapter(instance);
    mock.onAny("/foo").reply(200);

    instance.get("/foo").then(() => {
      expect(mock.history.get.length).assertEqual(1);
      expect(mock.history.get[0].method).assertEqual("get");
      expect(mock.history.get[0].url).assertEqual("/foo");
    });
  });
});
```

可使用 `resetHistory` 清除历史记录：

```typescript
mock.resetHistory();
```

## 约束与限制

* DevEco Studio版本：DevEco Studio 5.0.0 Release及以上
* HarmonyOS SDK版本：HarmonyOS 5.0.0 Release SDK及以上
* 设备类型：华为手机（包括双折叠和阔折叠）、华为平板
* 系统版本：HarmonyOS 5.0.0(12)及以上。