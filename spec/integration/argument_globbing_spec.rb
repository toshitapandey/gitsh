require 'spec_helper'

describe 'Glob patterns in arguments' do
  context 'brace expansion' do
    it 'expands to include each option' do
      GitshRunner.interactive do |gitsh|
        gitsh.type(':echo h{i,o}p')

        expect(gitsh).to output_no_errors
        expect(gitsh).to output(/hip hop/)
      end
    end

    it 'expands multiple expansions in one argument' do
      GitshRunner.interactive do |gitsh|
        gitsh.type(':echo 1{a,b}{x,y,z}')

        expect(gitsh).to output_no_errors
        expect(gitsh).to output(/1ax 1ay 1az 1bx 1by 1bz/)
      end
    end

    it 'expands empty options' do
      GitshRunner.interactive do |gitsh|
        gitsh.type(':echo git{,,sh,,}')

        expect(gitsh).to output_no_errors
        expect(gitsh).to output(/git git gitsh git git/)
      end
    end

    it 'expands nested expansions' do
      GitshRunner.interactive do |gitsh|
        gitsh.type(':echo f{{e,i,o}e,um}')

        expect(gitsh).to output_no_errors
        expect(gitsh).to output(/fee fie foe fum/)
      end
    end

    it 'supports escaped commas' do
      GitshRunner.interactive do |gitsh|
        gitsh.type(':echo 1{x,y\\,z}2')

        expect(gitsh).to output_no_errors
        expect(gitsh).to output(/1x2 1y,z2/)
      end
    end

    it 'supports escaped braces' do
      GitshRunner.interactive do |gitsh|
        gitsh.type(':echo 1{x,\\{,\\}}2')

        expect(gitsh).to output_no_errors
        expect(gitsh).to output(/1x2 1{2 1}2/)
      end
    end
  end

  context 'wild cards (?)' do
    it 'expands to include available arguments' do
      GitshRunner.interactive do |gitsh|
        write_file('foo1.txt', 'First test')
        write_file('foo2.txt', 'Second test')
        write_file('foo32.txt', 'Bad test')

        gitsh.type('!cat foo?.txt')

        expect(gitsh).to output_no_errors
        expect(gitsh).to output(/First test/)
        expect(gitsh).to output(/Second test/)
        expect(gitsh).not_to output(/Bad test/)
      end
    end
  end
end
