Rails.application.routes.draw do
  api_routes = proc do
    post "users", to: "users#create"
    post "users/login", to: "users#login"
    get "user", to: "users#show"
    put "user", to: "users#update"

    get "profiles/:username", to: "profiles#show"
    post "profiles/:username/follow", to: "profiles#follow"
    delete "profiles/:username/follow", to: "profiles#unfollow"

    get "articles/feed", to: "articles#feed"
    get "articles", to: "articles#index"
    post "articles", to: "articles#create"
    get "articles/:slug", to: "articles#show"
    put "articles/:slug", to: "articles#update"
    delete "articles/:slug", to: "articles#destroy"
    post "articles/:slug/favorite", to: "articles#favorite"
    delete "articles/:slug/favorite", to: "articles#unfavorite"
    get "articles/:slug/comments", to: "comments#index"
    post "articles/:slug/comments", to: "comments#create"
    delete "articles/:slug/comments/:comment_id", to: "comments#destroy"
    get "tags", to: "tags#index"
  end

  scope "api", &api_routes
  scope "api/v1", &api_routes
end
