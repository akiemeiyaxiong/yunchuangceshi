# 即梦AI - 素材提取(POD按需定制) API文档

## 接口简介

通过智能图案提取技术，从实物商品中精准提取并矢量化核心图案，生成平面设计图，提升电商领域中商品打版和产品设计等场景的制作效率。

## 限制条件

| 名称 | 内容 |
|------|------|
| 输入图要求 | 图片格式：仅支持JPEG、PNG格式，建议使用JPEG格式 |
| 图片分辨率 | 最大 4096 * 4096 |

## 请求说明

| 名称 | 内容 |
|------|------|
| 接口地址 | https://visual.volcengineapi.com |
| 请求方式 | POST |
| Content-Type | application/json |
| Region | cn-north-1 |
| Service | cv |

---

## 一、提交任务

### Query参数

| 参数 | 类型 | 可选/必选 | 说明 |
|------|------|-----------|------|
| Action | string | 必选 | 接口名，取值：`CVSync2AsyncSubmitTask` |
| Version | string | 必选 | 版本号，取值：`2022-08-31` |

### Header参数

主要用于鉴权，详见火山引擎签名参数文档。固定值：
- Region: cn-north-1
- Service: cv

### Body参数

| 名称 | 类型 | 必选 | 描述 |
|------|------|------|------|
| req_key | string | 必选 | 服务标识，取固定值: `i2i_material_extraction` |
| binary_data_base64 | array of string | 必选（二选一） | 图片文件base64编码，需输入1张图片 |
| image_urls | array of string | 必选（二选一） | 图片文件URL，需输入1张图片 |
| image_edit_prompt | string | 必选 | 编辑指令提示词 |
| lora_weight | float | 可选 | lora权重，默认值：1.000 |
| width | int | 可选 | 生成图片宽，默认值：2048，取值范围：[1024, 4096] |
| height | int | 可选 | 生成图片高，默认值：2048，取值范围：[1024, 4096] |
| seed | int | 可选 | 随机种子，默认-1（随机）。若随机种子为相同正整数且其他参数均一致，则生成内容极大概率效果一致 |

### image_edit_prompt 支持的提示词类型（四选一，必填）

| 类型 | 提示词内容 |
|------|------------|
| 提取图案 | 提取产品的图案，生成一张平面图展示其图案，去除产品本身。 |
| 提取包装 | 提取产品的包装图案，生成一张平面图展示其图案，去除产品本身。 |
| 提取logo | 提取产品的logo，生成一张平面图展示其logo，去除产品本身。 |
| 提取纹理 | 提取产品的纹理，生成一张平面图平铺展示其纹理，去除产品本身。 |

> 注意：以上提示词必填，可在此基础上增加其他提示词

### 返回参数

| 字段 | 类型 | 说明 |
|------|------|------|
| code | int | 状态码，10000表示成功 |
| data.task_id | string | 任务ID，用于查询结果 |
| message | string | 状态信息 |
| request_id | string | 请求ID |
| time_elapsed | string | 耗时 |

### 请求示例

```json
{
    "req_key": "i2i_material_extraction",
    "image_urls": [
        "https://xxxx"
    ],
    "image_edit_prompt": "提取产品的图案，生成一张平面图展示其图案，去除产品本身。"
}
```

### 返回示例

```json
{
    "code": 10000,
    "data": {
        "task_id": "7392616336519610409"
    },
    "message": "Success",
    "request_id": "20240720103939AF0029465CF6A74E51EC",
    "time_elapsed": "104.852309ms"
}
```

---

## 二、查询任务

### Query参数

| 参数 | 类型 | 可选/必选 | 说明 |
|------|------|-----------|------|
| Action | string | 必选 | 接口名，固定值：`CVSync2AsyncGetResult` |
| Version | string | 必选 | 版本号，固定值：`2022-08-31` |

### Body参数

| 参数 | 类型 | 可选/必选 | 说明 |
|------|------|-----------|------|
| req_key | string | 必选 | 服务标识，取固定值: `i2i_material_extraction` |
| task_id | string | 必选 | 任务ID，此字段的取值为提交任务接口的返回 |
| req_json | string | 可选 | json序列化后的字符串，支持水印配置和是否以图片链接形式返回 |

### req_json 配置信息

```json
{
    "logo_info": {
        "add_logo": true,
        "position": 0,
        "language": 0,
        "opacity": 1,
        "logo_text_content": "这里是明水印内容"
    },
    "return_url": true
}
```

| 参数 | 类型 | 可选/必选 | 说明 |
|------|------|-----------|------|
| return_url | bool | 可选 | 输出是否返回图片链接（链接有效期为24小时） |
| logo_info | LogoInfo | 可选 | 水印信息 |

### LogoInfo 水印相关信息

| 名称 | 类型 | 可选/必选 | 描述 |
|------|------|-----------|------|
| add_logo | bool | 可选 | 是否添加水印。True为添加，False不添加。默认不添加 |
| position | int | 可选 | 水印的位置 |
| language | int | 可选 | 水印语言 |
| opacity | float | 可选 | 水印透明度 |
| logo_text_content | string | 可选 | 明水印内容 |

### 查询任务请求示例

```json
{
    "req_key": "i2i_material_extraction",
    "task_id": "7392616336519610409",
    "req_json": "{\"return_url\": true}"
}
```

---

## 三、签名认证

### 重要说明

火山引擎API**不直接传递AK/SK**，而是通过签名认证机制：
- **Access Key ID (AK)**：访问密钥，会出现在Authorization Header中
- **Secret Access Key (SK)**：秘密密钥，**永远不会在网络中传输**，仅用于本地计算签名
- 签名过程在客户端完成，服务端通过相同的算法验证签名有效性

### 前置条件

1. 通过火山访问控制获取AK/SK，需确保火山账号已开通对应权限和相关策略
2. 无权限情况下会报错

### 签名流程

```
1. 构造规范化请求 (Canonical Request)
   ↓
2. 构造待签名字符串 (String to Sign)
   ↓
3. 使用SK计算签名 (Calculate Signature)
   ↓
4. 将签名添加到Authorization Header
```

### 关键Header参数

| 参数 | 说明 | 示例 |
|------|------|------|
| Authorization | 签名认证信息，包含AK和签名结果 | `HMAC-SHA256 Credential=AK****/20240720/cn-north-1/cv/request, SignedHeaders=host;x-date;x-content-sha256;content-type, Signature=xxxx` |
| X-Date | 请求时间，格式：yyyyMMdd'T'HHmmss'Z' | `20240720T103939Z` |
| X-Content-Sha256 | 请求体的SHA256哈希值 | `e3b0c44298fc1c149afbf4c8996fb924...` |
| Content-Type | 内容类型 | `application/json` |

### Authorization Header 格式

```
HMAC-SHA256 Credential={AccessKeyID}/{ShortDate}/{Region}/{Service}/request, SignedHeaders={SignedHeaders}, Signature={Signature}
```

各部分说明：
- **Credential**：包含AK、日期、区域、服务名
- **SignedHeaders**：参与签名的Header列表
- **Signature**：计算出的签名值

### 完整签名示例（Node.js）

```javascript
const crypto = require('crypto');

class VolcEngineSigner {
    constructor(accessKeyId, secretAccessKey, region, service) {
        this.ak = accessKeyId;
        this.sk = secretAccessKey;
        this.region = region;
        this.service = service;
    }

    sign(method, path, query, body, date) {
        const hashedPayload = this.hashSHA256(body);
        const xDate = this.formatDate(date);
        const shortDate = xDate.substring(0, 8);

        const canonicalRequest = this.buildCanonicalRequest(
            method, path, query, hashedPayload, xDate
        );
        
        const stringToSign = this.buildStringToSign(
            canonicalRequest, xDate, shortDate
        );
        
        const signature = this.calculateSignature(stringToSign, shortDate);
        
        return {
            'Authorization': this.buildAuthorizationHeader(shortDate, signature),
            'X-Date': xDate,
            'X-Content-Sha256': hashedPayload,
            'Content-Type': 'application/json'
        };
    }

    hashSHA256(data) {
        return crypto.createHash('sha256').update(data).digest('hex');
    }

    formatDate(date) {
        return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
    }

    buildCanonicalRequest(method, path, query, hashedPayload, xDate) {
        const signedHeaders = 'host;x-date;x-content-sha256;content-type';
        const canonicalHeaders = 
            `host:visual.volcengineapi.com\n` +
            `x-date:${xDate}\n` +
            `x-content-sha256:${hashedPayload}\n` +
            `content-type:application/json\n`;
        
        return [
            method,
            path,
            this.buildQueryString(query),
            canonicalHeaders,
            signedHeaders,
            hashedPayload
        ].join('\n');
    }

    buildStringToSign(canonicalRequest, xDate, shortDate) {
        const hashedCanonicalRequest = this.hashSHA256(canonicalRequest);
        return [
            'HMAC-SHA256',
            xDate,
            `${shortDate}/${this.region}/${this.service}/request`,
            hashedCanonicalRequest
        ].join('\n');
    }

    calculateSignature(stringToSign, shortDate) {
        const kDate = this.hmac(shortDate, this.sk);
        const kRegion = this.hmac(this.region, kDate);
        const kService = this.hmac(this.service, kRegion);
        const kSigning = this.hmac('request', kService);
        return this.hmac(stringToSign, kSigning, 'hex');
    }

    hmac(data, key, encoding) {
        return crypto.createHmac('sha256', key)
            .update(data)
            .digest(encoding || 'buffer');
    }

    buildAuthorizationHeader(shortDate, signature) {
        const signedHeaders = 'host;x-date;x-content-sha256;content-type';
        return `HMAC-SHA256 ` +
            `Credential=${this.ak}/${shortDate}/${this.region}/${this.service}/request, ` +
            `SignedHeaders=${signedHeaders}, ` +
            `Signature=${signature}`;
    }

    buildQueryString(query) {
        return Object.keys(query)
            .sort()
            .map(k => `${encodeURIComponent(k)}=${encodeURIComponent(query[k])}`)
            .join('&');
    }
}

// 使用示例
const signer = new VolcEngineSigner(
    'AK****',           // 你的Access Key ID
    '******==',         // 你的Secret Access Key
    'cn-north-1',       // Region
    'cv'                // Service
);

const body = JSON.stringify({
    req_key: 'i2i_material_extraction',
    image_urls: ['https://your-image-url.jpg'],
    image_edit_prompt: '提取产品的图案，生成一张平面图展示其图案，去除产品本身。'
});

const headers = signer.sign(
    'POST',
    '/',
    { Action: 'CVSync2AsyncSubmitTask', Version: '2022-08-31' },
    Buffer.from(body),
    new Date()
);

console.log(headers);
// 输出包含 Authorization, X-Date, X-Content-Sha256, Content-Type
```

---

## 四、完整调用流程

### 步骤1：提交任务

```bash
curl -X POST 'https://visual.volcengineapi.com?Action=CVSync2AsyncSubmitTask&Version=2022-08-31' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: <签名>' \
  -H 'X-Date: <时间戳>' \
  -H 'X-Content-Sha256: <body哈希>' \
  -d '{
    "req_key": "i2i_material_extraction",
    "image_urls": ["https://your-image-url.jpg"],
    "image_edit_prompt": "提取产品的图案，生成一张平面图展示其图案，去除产品本身。"
  }'
```

### 步骤2：轮询查询结果

使用返回的 `task_id` 查询任务状态：

```bash
curl -X POST 'https://visual.volcengineapi.com?Action=CVSync2AsyncGetResult&Version=2022-08-31' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: <签名>' \
  -H 'X-Date: <时间戳>' \
  -H 'X-Content-Sha256: <body哈希>' \
  -d '{
    "req_key": "i2i_material_extraction",
    "task_id": "7392616336519610409",
    "req_json": "{\"return_url\": true}"
  }'
```

### 步骤3：获取结果

查询接口返回的图片URL即为提取结果，链接有效期为24小时。

---

## 五、错误码说明

| 错误码 | 说明 |
|--------|------|
| 10000 | 成功 |
| 其他 | 请求失败，请检查参数或权限 |

---

## 六、注意事项

1. 图片链接有效期为24小时，请及时下载保存
2. 隐式标识验证方式：
   - 查看【png】或【mp4】格式：访问 https://www.gcmark.com/web/index.html#/mark/check/image
   - 查看【jpg】格式：使用app11 segment查看aigc元数据内容
3. 建议使用JPEG格式输入图片以获得更好的处理效果
4. 同一任务可多次查询直到获取结果

---

## 七、参考链接

- [即梦AI-素材提取接口文档](https://www.volcengine.com/docs/85621/1925087?lang=zh)
- [HTTP请求示例](https://www.volcengine.com/docs/6444/1390583?lang=zh)
- [火山引擎公共参数签名文档](https://www.volcengine.com/docs/6444/1390583)
