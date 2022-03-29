## 使用前你需要
- ruby 3.1.0
- [GitHub OAuth Apps](https://github.com/settings/developers)

## 安装和配置

命令行执行
```shell
bundle install
```

然后在项目目录下创建 `config.yaml`，内容： 
```yaml
OAUTH_APP_ID: your_oauth_app_id
OAUTH_APP_SECRET: your_oauth_app_secret
```

修改 `app.rb`：
```ruby
USER_NAME = 'your github user name'
```

然后执行：
```shell
ruby ./app.rb
```

