require 'rest-client'
require 'json'
require 'yaml'

# 用户信息
USER_NAME = 'yuchiXiong'.freeze
OAUTH_INFO = YAML.load_file('./config.yaml')

# 请求接口路径
GITHUB_API_DOMAIN   = 'https://api.github.com'.freeze
FOLLOWING_USERS_API = "#{GITHUB_API_DOMAIN}/users/#{USER_NAME}/following".freeze

# 公共请求参数
COMMON_HEADERS = {
  'Accept': 'application/vnd.github.v3+json'.freeze
}.freeze


# other const
LAST_TIME = 7 * 24 * 60 * 60


# 请求方法
def request(url:, method: :get)
  RestClient::Request.execute(
      method:,
      url:,
      user: OAUTH_INFO['OAUTH_APP_ID'],
      password: OAUTH_INFO['OAUTH_APP_SECRET'],
      headers: COMMON_HEADERS
  )
end

result = []

following_users_response = request(url: "#{FOLLOWING_USERS_API}?page=1&per_page=100")

puts '由于 GitHub 公开 API 的请求限制，请留意您的账户可用请求余额。详情请访问 https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting'
result << '由于 GitHub 公开 API 的请求限制，请留意您的账户可用请求余额。详情请访问 https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting'
puts "当前 账户/IP 请求总量（次/时）  #{following_users_response.headers[:x_ratelimit_limit]}"
result << "当前 账户/IP 请求总量（次/时）  #{following_users_response.headers[:x_ratelimit_limit]}"
puts "当前 账户/IP 请求余额（次/时）  #{following_users_response.headers[:x_ratelimit_remaining]}"
result << "当前 账户/IP 请求余额（次/时）  #{following_users_response.headers[:x_ratelimit_remaining]}"
puts "当前 账户/IP 总量刷新时间  #{Time.at(following_users_response.headers[:x_ratelimit_reset].to_i).strftime('%F %T')}"
result << "当前 账户/IP 总量刷新时间  #{Time.at(following_users_response.headers[:x_ratelimit_reset].to_i).strftime('%F %T')}"
puts "当前 账户/IP 已用总量（次/时）  #{following_users_response.headers[:x_ratelimit_used]}"
result << "当前 账户/IP 已用总量（次/时）  #{following_users_response.headers[:x_ratelimit_used]}"
puts ''
result << "\n"

following_users = JSON.parse(following_users_response.body).map { |u| u['login'] }

puts "用户 #{USER_NAME} 的关注列表："
result << "用户 #{USER_NAME} 的关注列表："
p following_users
result << following_users.join(' ')
puts ''
result << "\n"

following_users.each do |user|
  page = 1
  show = false
  loop do
    user_repos_response = request(url: "#{GITHUB_API_DOMAIN}/users/#{user}/repos?per_page=100&page=#{page}&type=all".freeze).body

    user_repos = JSON.parse(user_repos_response)

    break if user_repos.size.zero?

    user_repos
      .reject { |repo| repo['fork'] || repo['archived'] }
      .select { |repo| (Time.parse(repo['pushed_at']).to_i + LAST_TIME) > Time.now.to_i }
      .map do |repo|
      since = Time.at(Time.now.to_i - LAST_TIME).strftime('%FT%TZ')
      params = "per_page=100&page=1&author=#{user}&since=#{since}"
      commits_response = request(
        url: "#{GITHUB_API_DOMAIN}/repos/#{repo['full_name']}/commits?#{params}".freeze
      ).body

      commits = JSON.parse(commits_response)

      break if commits.size.zero?

      unless show
        puts ">>>> @#{user} [https://github.com/#{user}]: " if page == 1
        result << ">>>> @#{user} [https://github.com/#{user}]: " if page == 1
        show = true
      end

      commits.each do |commit|
        puts "[#{commit['commit']['author']['date']}] ~#{repo['full_name']} : #{commit['commit']['message']}"
        result << "[#{commit['commit']['author']['date']}] ~#{repo['full_name']} : #{commit['commit']['message']}"
      end
    end

    page += 1
  end

  if show
    puts ''
    result << "\n"
  end
end

afile = File.open('./result', 'wb+')
afile.syswrite(result.join("\n"))
afile.close
