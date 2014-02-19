# WARNING THIS APPLICATION IS VULNERABLE TO XSRF
# ALTHOUGH IT IS SLIGHTLY BETTER THAN THE OLD VERSION.. SOME PARTS WILL _NEED_ A REWRITE
# IN CASE YOU ARE BORED, PLEASE TAKE ALL METHODS THAT ARE REACHABLE VIA GET AND POST AND SPLIT THEM UP 
# KTHX

MyMaxnetAo::Application.routes.draw do

  #match ':locale/feedback/ticket/:id/:ticket_token' => 'feedback#show', :as => :ticket_feedback

  scope "(:locale)", :locale => /en|pt|de/ do
    resources :tickets 
    resources :customer_announcements
    resources :feedback
    resources :aliases do 
      collection do 
        get :invalid_setup 
      end
    end
    resources :hotspot do 
      collection do
        get :buy,:buy_batch,:view,:account,:cancel,:ticket_status
        post :buy,:buy_batch,:ticket_status
      end
    end
    resources :email do 
      collection do 
        get :invalid_setup,:view,:add,:change,:edit,:settings
        post :delete,:add,:change,:edit
      end
    end
    resources :circuit do
      collection do 
        get :display_graph,:devices,:configuration,:graph,:payg,:monitoring,:smokeping,:smokeping_generate
      end
    end
    resources :support do
      collection do 
        get :contact_add,:contact_edit,:contact_delete,:technical,:sales
        post :contact_add,:contact_edit,:contact_delete
      end
    
    end
    resource :sessions do
      collection do 
        get :login,:password,:welcome,:login_email,:logout, :index
        post :login,:password,:login_email
      end 
    end
    #match '/signup/:permalink',  to: 'users#new', :as => 'signup'
    #match '/login', to: 'sessions#new', :as=>'login'
  end
  root :to => "sessions#index"

end
