defmodule HomesiteWeb.FaqLiveTest do
  use HomesiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  import Homesite.FaqsFixtures

  alias Homesite.Faqs

  describe "Index - Public users" do
    test "renders FAQ page for unauthenticated users", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/faqs")

      assert html =~ "Frequently asked questions"
    end

    test "shows only active user FAQs to public", %{conn: conn} do
      # Create admin scope and FAQs
      admin_scope = admin_scope_fixture()

      # Create active user FAQ
      _active_faq =
        user_faq_fixture(admin_scope, %{
          question_en: "Public Question",
          answer_en: "Public Answer",
          is_active: true
        })

      # Create inactive user FAQ
      _inactive_faq =
        user_faq_fixture(admin_scope, %{
          question_en: "Hidden Question",
          answer_en: "Hidden Answer",
          is_active: false
        })

      # Create admin FAQ
      _admin_faq =
        admin_faq_fixture(admin_scope, %{
          question_en: "Admin Question",
          answer_en: "Admin Answer"
        })

      {:ok, _index_live, html} = live(conn, ~p"/faqs")

      # Should show active user FAQ
      assert html =~ "Public Question"
      assert html =~ "Public Answer"

      # Should NOT show inactive user FAQ
      refute html =~ "Hidden Question"

      # Should NOT show admin FAQ to public
      refute html =~ "Admin Question"
    end

    test "public users cannot see edit/delete buttons", %{conn: conn} do
      admin_scope = admin_scope_fixture()

      _faq =
        user_faq_fixture(admin_scope, %{
          question_en: "Test Question",
          answer_en: "Test Answer"
        })

      {:ok, index_live, _html} = live(conn, ~p"/faqs")

      # Check for absence of admin action buttons (not just text, as FAQ content may contain "Edit")
      refute has_element?(index_live, "a", "Edit")
      refute has_element?(index_live, "button", "Delete")
      refute has_element?(index_live, "a", "New FAQ")
    end
  end

  describe "Index - Regular users" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "renders FAQ page for authenticated regular users", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/faqs")

      assert html =~ "Frequently asked questions"
    end

    test "regular users see only user FAQs", %{conn: conn} do
      admin_scope = admin_scope_fixture()

      _user_faq =
        user_faq_fixture(admin_scope, %{
          question_en: "User Question",
          answer_en: "User Answer"
        })

      _admin_faq =
        admin_faq_fixture(admin_scope, %{
          question_en: "Admin Question",
          answer_en: "Admin Answer"
        })

      {:ok, _index_live, html} = live(conn, ~p"/faqs")

      assert html =~ "User Question"
      refute html =~ "Admin Question"
    end

    test "regular users cannot see edit/delete buttons", %{conn: conn} do
      admin_scope = admin_scope_fixture()

      _faq =
        user_faq_fixture(admin_scope, %{
          question_en: "Test Question",
          answer_en: "Test Answer"
        })

      {:ok, index_live, _html} = live(conn, ~p"/faqs")

      # Check for absence of admin action buttons (not just text, as FAQ content may contain "Edit")
      refute has_element?(index_live, "a", "Edit")
      refute has_element?(index_live, "button", "Delete")
      refute has_element?(index_live, "a", "New FAQ")
    end
  end

  describe "Index - Admin users" do
    setup %{conn: conn} do
      admin_scope = admin_scope_fixture()

      %{
        conn: log_in_user(conn, admin_scope.user),
        admin: admin_scope.user,
        admin_scope: admin_scope
      }
    end

    test "renders FAQ page for admin users", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/faqs")

      assert html =~ "Frequently asked questions"
      assert html =~ "New FAQ"
    end

    test "admin can see edit and delete buttons", %{conn: conn, admin_scope: admin_scope} do
      _faq =
        user_faq_fixture(admin_scope, %{
          question_en: "Test Question",
          answer_en: "Test Answer"
        })

      {:ok, _index_live, html} = live(conn, ~p"/faqs")

      assert html =~ "Edit"
      assert html =~ "Delete"
    end

    test "admin can toggle between user and admin FAQs", %{conn: conn, admin_scope: admin_scope} do
      _user_faq =
        user_faq_fixture(admin_scope, %{
          question_en: "User Question",
          answer_en: "User Answer"
        })

      _admin_faq =
        admin_faq_fixture(admin_scope, %{
          question_en: "Admin Question",
          answer_en: "Admin Answer"
        })

      # Default view shows user FAQs
      {:ok, _view, html} = live(conn, ~p"/faqs")
      assert html =~ "User Question"
      refute html =~ "Admin Question"

      # Navigate to admin FAQs
      {:ok, _view, html} = live(conn, ~p"/faqs?category=admin")
      assert html =~ "Admin Question"
      refute html =~ "User Question"
    end

    test "admin can delete FAQ", %{conn: conn, admin_scope: admin_scope} do
      faq =
        user_faq_fixture(admin_scope, %{
          question_en: "To Delete",
          answer_en: "Will be deleted"
        })

      {:ok, index_live, _html} = live(conn, ~p"/faqs")

      assert index_live
             |> element("button[phx-click='delete'][phx-value-id='#{faq.id}']")
             |> render_click()

      assert_raise Ecto.NoResultsError, fn ->
        Faqs.get_faq_for_management!(admin_scope, faq.id)
      end
    end
  end

  describe "Form - Create FAQ" do
    setup %{conn: conn} do
      admin_scope = admin_scope_fixture()

      %{
        conn: log_in_user(conn, admin_scope.user),
        admin: admin_scope.user,
        admin_scope: admin_scope
      }
    end

    test "renders new FAQ form", %{conn: conn} do
      {:ok, _form_live, html} = live(conn, ~p"/faqs/new")

      assert html =~ "New FAQ"
      assert html =~ "Question (English)"
      assert html =~ "Question (Finnish)"
    end

    test "creates FAQ successfully", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/faqs/new")

      assert form_live
             |> form("#faq-form",
               faq: %{
                 category: "user",
                 question_en: "How to post?",
                 question_fi: "Miten julkaista?",
                 answer_en: "Click the button",
                 answer_fi: "Klikkaa nappia",
                 display_order: 10,
                 is_active: true
               }
             )
             |> render_submit()

      assert_redirected(form_live, ~p"/faqs")
    end

    test "validates required fields", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/faqs/new")

      result =
        form_live
        |> form("#faq-form",
          faq: %{
            category: "user",
            question_en: "",
            question_fi: "",
            answer_en: "",
            answer_fi: ""
          }
        )
        |> render_change()

      assert result =~ "can&#39;t be blank"
    end
  end

  describe "Form - Edit FAQ" do
    setup %{conn: conn} do
      admin_scope = admin_scope_fixture()

      faq =
        user_faq_fixture(admin_scope, %{
          question_en: "Original Question",
          answer_en: "Original Answer"
        })

      %{
        conn: log_in_user(conn, admin_scope.user),
        admin: admin_scope.user,
        admin_scope: admin_scope,
        faq: faq
      }
    end

    test "renders edit FAQ form", %{conn: conn, faq: faq} do
      {:ok, _form_live, html} = live(conn, ~p"/faqs/#{faq}/edit")

      assert html =~ "Edit FAQ"
      assert html =~ "Original Question"
    end

    test "updates FAQ successfully", %{conn: conn, faq: faq} do
      {:ok, form_live, _html} = live(conn, ~p"/faqs/#{faq}/edit")

      assert form_live
             |> form("#faq-form",
               faq: %{
                 question_en: "Updated Question",
                 answer_en: "Updated Answer"
               }
             )
             |> render_submit()

      assert_redirected(form_live, ~p"/faqs")
    end
  end

  describe "Security" do
    test "regular users cannot access FAQ creation form", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # This should redirect or show error since route is in :require_admin session
      # The actual behavior depends on your on_mount hooks
      assert {:error, {:redirect, %{to: _}}} = live(conn, ~p"/faqs/new")
    end

    test "regular users cannot access FAQ edit form", %{conn: conn} do
      admin_scope = admin_scope_fixture()

      faq =
        user_faq_fixture(admin_scope, %{
          question_en: "Test",
          answer_en: "Test Answer"
        })

      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: _}}} = live(conn, ~p"/faqs/#{faq}/edit")
    end
  end
end
