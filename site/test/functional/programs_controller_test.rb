require File.dirname(__FILE__) + '/../test_helper'

class ProgramsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:programs)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_program
    assert_difference('Program.count') do
      post :create, :program => { }
    end

    assert_redirected_to program_path(assigns(:program))
  end

  def test_should_show_program
    get :show, :id => programs(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => programs(:one).id
    assert_response :success
  end

  def test_should_update_program
    put :update, :id => programs(:one).id, :program => { }
    assert_redirected_to program_path(assigns(:program))
  end

  def test_should_destroy_program
    assert_difference('Program.count', -1) do
      delete :destroy, :id => programs(:one).id
    end

    assert_redirected_to programs_path
  end
end
