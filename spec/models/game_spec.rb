require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  describe 'Creating new game' do
    before do
      generate_questions(60)

      expect {
        Game.create_game_for_user!(user)
        # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
      }.to change(Game, :count).by(1).and(
        # GameQuestion.count +15
        change(GameQuestion, :count).by(15).and(
          # Game.count не должен измениться
          change(Question, :count).by(0)
        ))
    end

    let(:game) { Game.create_game_for_user!(user) }

    context 'game creation process' do
      it 'create a game with specified user' do
        expect(game.user).to eq(user)
      end

      it 'create a game with status in progress' do
        expect(game.status).to eq(:in_progress)
      end

      it 'create a game with 15 questions' do
        expect(game.game_questions.size).to eq(15)
      end

      it 'create a game with questions levels from 0 to 14' do
        expect(game.game_questions.map(&:level)).to eq (0..14).to_a
      end
    end
  end

  # Тесты на основную игровую логику
  describe 'game mechanics' do
    # Правильный ответ должен продолжать игру
    context 'when answer is correct' do
      it 'continue the game' do
        level = game_w_questions.current_level
        q = game_w_questions.current_game_question

        expect(game_w_questions.status).to eq(:in_progress)

        game_w_questions.answer_current_question!(q.correct_answer_key)

        # Перешли на след. уровень
        expect(game_w_questions.current_level).to eq(level + 1)

        # Ранее текущий вопрос стал предыдущим
        expect(game_w_questions.current_game_question).not_to eq(q)

        # Игра продолжается
        expect(game_w_questions.status).to eq(:in_progress)
        expect(game_w_questions.finished?).to be false
      end
    end

    context 'when take the money' do
      it 'finish the game' do
        # берем игру и отвечаем на текущий вопрос
        q = game_w_questions.current_game_question
        game_w_questions.answer_current_question!(q.correct_answer_key)

        # взяли деньги
        game_w_questions.take_money!

        prize = game_w_questions.prize
        expect(prize).to be > 0

        # проверяем что закончилась игра и пришли деньги игроку
        expect(game_w_questions.status).to eq :money
        expect(game_w_questions.finished?).to be true
        expect(user.balance).to eq prize
      end
    end
  end

  # группа тестов на проверку статуса игры
  describe '.status' do
    # перед каждым тестом "завершаем игру"
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be true
    end

    context 'when the game is won' do
      it 'return status :won' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
        expect(game_w_questions.status).to eq(:won)
      end
    end

    context 'when the game is fail' do
      it 'return status :fail' do
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:fail)
      end
    end

    context 'when time expired' do
      it 'return status :timeout' do
        game_w_questions.created_at = 1.hour.ago
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:timeout)
      end
    end

    context 'when decided to take the money' do
      it 'return status :money' do
        expect(game_w_questions.status).to eq(:money)
      end
    end
  end

  describe '.previous_level' do
    context 'when current level is 0' do
      it 'return -1' do
        game_w_questions.current_level = 0
        expect(game_w_questions.previous_level).to eq(-1)
      end
    end

    context 'when current level is 12' do
      it 'return 11' do
        game_w_questions.current_level = 12
        expect(game_w_questions.previous_level).to eq(11)
      end
    end
  end

  context '.current_game_question' do
    it 'return current game question' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions.first)
    end
  end

  describe '.answer_current_question!' do
    before do
      game_w_questions.answer_current_question!(answer_key)
    end

    # let(:question) { game_w_questions.current_game_question }

    context 'when correct answer' do
      let!(:answer_key) { game_w_questions.current_game_question.correct_answer_key }

      context 'when answer to the last question' do
        let!(:level) { Question::QUESTION_LEVELS.max }
        let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user, current_level: level) }

        it 'finish the game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'set status :won' do
          expect(game_w_questions.status).to eq(:won)
        end

        it 'get the grand prize' do
          expect(game_w_questions.prize).to eq(Game::PRIZES.last)
        end

        it 'increase the balance' do
          expect(user.balance).to eq(Game::PRIZES[Question::QUESTION_LEVELS.max])
        end
      end

      context 'when the question is not the last' do
        it 'go to the next game level' do
          # game_w_questions.answer_current_question!(question.correct_answer_key)
          expect(game_w_questions.current_level).to eq(1)
        end

        it 'change question' do
          expect(game_w_questions.current_game_question.level).to eq(1)
        end

        it 'continue game' do
          expect(game_w_questions.finished?).to be false
        end
      end

      context 'when answer is given after the time has expired' do
        let!(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user, current_level: 3, created_at: 1
                                                                                                                      .hour.ago) }
        it 'return false' do
          expect(game_w_questions.answer_current_question!(answer_key)).to be false
        end

        it 'finish the game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'finish with status timeout' do
          expect(game_w_questions.status).to eq(:timeout)
        end
      end
    end

    context 'when wrong answer' do
      let!(:answer_key) { (%w[a b c d] - [game_w_questions.current_game_question.correct_answer_key]).sample }

      it 'finish the game' do
        expect(game_w_questions.finished?).to be true
      end

      it 'return status fail' do
        expect(game_w_questions.status).to eq :fail
      end
    end
  end
end
