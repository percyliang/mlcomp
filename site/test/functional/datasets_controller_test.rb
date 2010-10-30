require File.dirname(__FILE__) + '/../test_helper'

class DatasetsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:datasets)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_dataset
    assert_difference('Dataset.count') do
      post :create, :dataset => { }
    end

    assert_redirected_to dataset_path(assigns(:dataset))
  end

  def test_should_show_dataset
    get :show, :id => datasets(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => datasets(:one).id
    assert_response :success
  end

  def test_should_update_dataset
    put :update, :id => datasets(:one).id, :dataset => { }
    assert_redirected_to dataset_path(assigns(:dataset))
  end

  def test_should_destroy_dataset
    assert_difference('Dataset.count', -1) do
      delete :destroy, :id => datasets(:one).id
    end

    assert_redirected_to datasets_path
  end
end
