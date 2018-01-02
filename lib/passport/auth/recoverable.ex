defmodule Passport.Auth.Recoverable do
  import Ecto.Changeset
  import Ecto.Query

  # for now
  @type t :: term

  defmacro schema_fields do
    quote do
      field :reset_password_token, :string
      field :reset_password_sent_at, :utc_datetime
    end
  end

  defmacro routes do
    quote do
      # Request a password reset
      post "/password", PasswordController, :create
      # Reset password
      put "/password/:token", PasswordController, :update
      # Clear reset password
      delete "/password/:token", PasswordController, :delete
    end
  end

  alias Passport.Keygen

  def generate_reset_password_token do
    Keygen.random_string(128)
  end

  def clear_reset_password(changeset) do
    changeset
    |> put_change(:reset_password_token, nil)
    |> put_change(:reset_password_sent_at, nil)
  end

  def prepare_reset_password(changeset) do
    changeset
    |> put_change(:reset_password_token, generate_reset_password_token())
    |> put_change(:reset_password_sent_at, DateTime.utc_now())
  end

  def by_reset_password_token(query, token) do
    where(query, reset_password_token: ^token)
  end
end
