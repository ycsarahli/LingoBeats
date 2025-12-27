# **LingoBeats**

An application that transforms *songs* into AI-generated *materials* for an engaging language-learning experience.

## **Overview**

LingoBeats will connect to **Spotify** to retrieve songs and **Genius** to fetch lyrics, then analyzes the text using **CEFR levels** to match content with each learner’s proficiency. 

Finally, **Gemini AI** generates personalized learning contents and exercises based on the linguistic insights extracted from the previous stages.

By combining music, AI, and intelligent content generation, LingoBeats hopes to turn passive listening into an interactive and personalized learning journey, boosting learners’ motivation.

## **Objectives**

### Short-term usability goals

1. Integrate Spotify and Genius APIs to retrieve and preprocess song and lyric data
2. Analyze word with CEFR levels
3. Get personalized learning materials using Gemini AI

### Long-term goals

1. Expand the platform to support multiple languages and cross-cultural learning
2. Build adaptive learning models that personalize content based on learner progress

## **System Design**

### Entity-Relationship Diagram
<p>
  <img src="app/presentation/public/er-diagram.svg" width="1200" alt="ERD Preview">
</p>

## **Setup**

1. Copy `config/secrets_example.yml` to `config/secrets.yml` and update api host
2. Ensure correct version of Ruby install (see `.ruby-version` for `rbenv`)
3. Run `bundle install`

## **Testing code quality**

<pre><code>rake quality:all</pre></code>

## **Running Application**

<pre><code>rake run</pre></code>