use reqwest::header;
use serde::{Deserialize, Serialize};
use std::fs;

#[derive(Serialize, Deserialize, Debug)]
struct Config {
    #[serde(rename(deserialize = "OAUTH_APP_ID"))]
    app_id: String,
    #[serde(rename(deserialize = "OAUTH_APP_SECRET"))]
    app_secret: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct FollowingUserList {
    login: String,
    id: u64,
    node_id: String,
    avatar_url: String,
    gravatar_id: String,
    url: String,
    html_url: String,
    followers_url: String,
    following_url: String,
    gists_url: String,
    starred_url: String,
    subscriptions_url: String,
    organizations_url: String,
    repos_url: String,
    events_url: String,
    received_events_url: String,
    r#type: String,
    site_admin: bool,
}

/** 载入 yaml 配置文件 */
fn get_config() -> Config {
    let root_path = std::env::current_dir().unwrap();

    let config_file = format!("{}/config.yaml", root_path.display());

    let file = fs::read_to_string(&config_file).unwrap();

    match serde_yaml::from_str(&file) {
        Ok(res) => res,
        Err(e) => {
            print!("{:?}", e);
            Config {
                app_id: String::from(""),
                app_secret: String::from(""),
            }
        }
    }
}

/** 获取当前用户关注的人的用户名列表 */
async fn fetch_following_list() -> Vec<String> {
    let github_api_domain = "https://api.github.com";
    let user_name = "yuchiXiong";

    let following_users_api = format!("{}/users/{}/following", github_api_domain, user_name);

    let mut headers = header::HeaderMap::new();
    headers.insert(
        "Accept",
        header::HeaderValue::from_static("application/vnd.github.v3+json"),
    );

    let config = get_config();
    let user_agent = format!("{}/{}", config.app_id, config.app_secret);

    let client = reqwest::Client::builder()
        .default_headers(headers)
        .user_agent(user_agent)
        .build()
        .unwrap();

    let res = client.get(following_users_api).send().await;

    match res {
        Ok(res) => {
            println!("由于 GitHub 公开 API 的请求限制，请留意您的账户可用请求余额。详情请访问 https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting");
            println!(
                "当前 账户/IP 请求总量（次/时）  {:?}",
                res.headers().get("x-ratelimit-limit").unwrap()
            );
            println!(
                "当前 账户/IP 请求余额（次/时）  {:?}",
                res.headers().get("x-ratelimit-remaining").unwrap()
            );
            println!(
                "当前 账户/IP 总量刷新时间  {:?}",
                res.headers().get("x-ratelimit-reset").unwrap()
            );
            println!(
                "当前 账户/IP 已用总量（次/时）  {:?}",
                res.headers().get("x-ratelimit-used").unwrap()
            );

            res.json::<Vec<FollowingUserList>>()
                .await
                .unwrap()
                .iter()
                .map(|f| f.login.to_string())
                .collect::<Vec<_>>()
        }
        Err(e) => Vec::new(),
    }
}

/** 拉取指定用户的所有活动 */
async fn fetch_activities_by_username(username: &String) -> Vec<String> {
    Vec::new()
}

#[tokio::main]
async fn main() {
    let following_list = fetch_following_list().await;

    println!("用户的关注列表：{:?}", following_list);

    // let logs = following_list
    //     .iter()
    //     .map(|username| async { fetch_activities_by_username(username).await })
    //     .
    let futures = following_list
        .into_iter()
        .map(|username| fetch_activities_by_username(&username))
        .collect();

    println!("{:?}", logs)
}
