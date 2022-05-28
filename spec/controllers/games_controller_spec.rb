require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  describe '#show' do
    context 'when the user is not logged in' do
      before { get :show, params: { id: game_w_questions.id } }

      it 'should return status not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'should redirect to the new session path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should be alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when the user is logged in' do
      before(:each) do
        sign_in user
        get :show, params: { id: game_w_questions.id }
        generate_questions(60)
      end

      let(:game) { assigns(:game) }

      context 'user views his game' do
        it 'game not over' do
          expect(game.finished?).to be_falsey
        end

        it 'game for this user' do
          expect(game.user).to eq(user)
        end

        it 'should' do
          expect(response.status).to eq(200)
        end

        it 'should' do
          expect(response).to render_template('show')
        end
      end
    end
  end

  describe '#create' do
    context 'when the user is not logged in' do
      before { post :create }

      it 'should return status not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'should redirect to the new session path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should be alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when the user is logged in' do
      before(:each) do
        sign_in user
        generate_questions(60)
        post :create
      end

      let(:game) { assigns(:game) }

      context 'game state not finished' do
        before do
          expect(game.finished?).to be false
        end

        it 'redirects to game in progress' do
          expect(response).to redirect_to(game_path(game))
        end
      end
    end
  end

  describe '#answer' do
    context 'when the user is not logged in' do
      before { put :answer, params: { id: game_w_questions.id } }

      it 'should return status not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'should redirect to the new session path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should be alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when the user is logged in' do
      before(:each) do
        sign_in user
        generate_questions(60)

        put :answer,
            params: { id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }
      end

      let(:game) { assigns(:game) }

      it ' should not be finished' do
        expect(game.finished?).to be_falsey
      end

      it 'current level should be > 0' do
        expect(game.current_level).to be > 0
      end

      it 'redirect to game in progress' do
        expect(response).to redirect_to(game_path(game))
      end

      it 'should not be flash' do
        expect(flash.empty?).to be_truthy
      end

      context 'correct answer' do

      end

      context 'wrong answer' do

      end
    end
  end

  describe '#take_money' do
    context 'when the user is not logged in' do
      before { put :take_money, params: { id: game_w_questions.id } }

      it 'should return status not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'should redirect to the new session path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should be alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when the user is logged in' do
      before(:each) do
        sign_in user
        put :take_money, params: { id: game_w_questions.id }
        generate_questions(60)
      end

      let(:game) { assigns(:game) }
    end
  end

  describe '#help' do
    context 'when the user is not logged in' do
      before { put :help, params: { id: game_w_questions.id } }

      it 'should return status not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'should redirect to the new session path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should be alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when the user is logged in' do
      before(:each) do
        sign_in user
        put :help, params: { id: game_w_questions.id }
        generate_questions(60)
      end

      let(:game) { assigns(:game) }
    end
  end
end
