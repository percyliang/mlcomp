require File.dirname(__FILE__) + '/../test_helper'

class RunsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:runs)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_run
    assert_difference('Run.count') do
      post :create, :run => { }
    end

    assert_redirected_to run_path(assigns(:run))
  end

  def test_should_show_run
    get :show, :id => runs(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => runs(:one).id
    assert_response :success
  end

  def test_should_update_run
    put :update, :id => runs(:one).id, :run => { }
    assert_redirected_to run_path(assigns(:run))
  end

  def test_should_destroy_run
    assert_difference('Run.count', -1) do
      delete :destroy, :id => runs(:one).id
    end

    assert_redirected_to runs_path
  end
end
