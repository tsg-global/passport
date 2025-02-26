defmodule Passport.Confirmable do
  import Ecto.Changeset
  import Ecto.Query

  defmacro schema_fields(options \\ []) do
    timestamp_type = Keyword.get(options, :timestamp_type, :utc_datetime_usec)
    quote do
      field :confirmation_token,   :string
      field :confirmed_at,         unquote(timestamp_type)
      field :confirmation_sent_at, unquote(timestamp_type)
    end
  end

  defmacro routes(opts \\ []) do
    confirmable_controller = Keyword.get(opts, :confirmable_controller, ConfirmationController)
    quote do
      # Confirm user email
      post "/confirm/email", unquote(confirmable_controller), :create
      get "/confirm/email/:token", unquote(confirmable_controller), :show
      post "/confirm/email/:token", unquote(confirmable_controller), :confirm
      delete "/confirm/email/:token", unquote(confirmable_controller), :delete
    end
  end

  def migration_fields(_mod) do
    [
      "# Confirmable",
      "add :confirmation_token,   :string",
      "add :confirmed_at,         :utc_datetime_usec",
      "add :confirmation_sent_at, :utc_datetime_usec",
    ]
  end

  def migration_indices(_mod) do
    # <users> will be replaced with the correct table name
    [
      "create unique_index(<users>, [:confirmation_token])"
    ]
  end

  alias Passport.Keygen

  @spec generate_confirmation_token(term) :: String.t
  def generate_confirmation_token(object \\ nil) do
    Keygen.random_string(Passport.Config.confirmation_token_length(object))
  end

  def confirm(changeset, params \\ %{}) do
    confirmed_at =  params[:confirmed_at] || Passport.Util.generate_timestamp_for(changeset, :confirmed_at)
    changeset
    |> put_change(:confirmation_token, nil)
    |> put_change(:confirmed_at, confirmed_at)
  end

  def new_confirmation(changeset, params \\ %{}) do
    confirmation_token = params[:confirmation_token] || generate_confirmation_token(changeset)
    confirmation_sent_at = params[:confirmation_sent_at] || Passport.Util.generate_timestamp_for(changeset, :confirmation_sent_at)
    changeset
    |> put_change(:confirmation_token, confirmation_token)
    |> put_change(:confirmation_sent_at, confirmation_sent_at)
  end

  def prepare_confirmation(changeset, params \\ %{}) do
    changeset
    |> new_confirmation(params)
    |> put_change(:confirmed_at, nil)
  end

  def cancel_confirmation(changeset) do
    changeset
    |> put_change(:confirmation_token, nil)
    |> put_change(:confirmation_sent_at, nil)
  end

  def by_confirmation_token(query, token) do
    where(query, confirmation_token: ^token)
  end

  @spec confirmed?(term) :: boolean
  def confirmed?(entity) do
    !!entity.confirmed_at
  end
end
