import re
import json
from transformers import pipeline, AutoTokenizer
from datetime import datetime, timedelta

class SubtitleEmotionAnalyzer:
    def __init__(self, model_name="j-hartmann/emotion-english-distilroberta-base", max_tokens=512):
        self.classifier = pipeline("text-classification", model=model_name, return_all_scores=True)
        self.tokenizer = AutoTokenizer.from_pretrained(model_name)
        self.max_tokens = max_tokens

    def time_to_seconds(self, time_str):
        time_format = "%H:%M:%S,%f"
        return (datetime.strptime(time_str, time_format) - datetime(1900, 1, 1)).total_seconds()

    def seconds_to_time(self, seconds):
        return str(timedelta(seconds=seconds))[:-3].replace('.', ',')

    def extract_subtitles_from_srt(self, srt_file):
        try:
            with open(srt_file, 'r', encoding='utf-8') as f:
                content = f.read()

            pattern = re.compile(r'(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})\n(.*?)\n\n', re.DOTALL)
            matches = pattern.findall(content)

            subtitles = []
            for match in matches:
                start_time, end_time, text = match
                text = text.replace('\n', ' ').strip()
                if text:
                    subtitles.append({
                        "start_time": start_time,
                        "end_time": end_time,
                        "text": text
                    })

            return subtitles
        except FileNotFoundError:
            print(f"Error: The file {srt_file} was not found.")
            return []
        except Exception as e:
            print(f"Error reading subtitle file: {str(e)}")
            return []

    def split_text_into_sentences(self, text):
        sentences = re.split(r'[.!?]+', text)
        return [s.strip() for s in sentences if s.strip()]

    def get_token_length(self, text):
        return len(self.tokenizer.encode(text, add_special_tokens=True))

    def create_subchunks(self, text):
        sentences = self.split_text_into_sentences(text)
        subchunks = []
        current_chunk = ""
        
        for sentence in sentences:
            potential_chunk = current_chunk + " " + sentence if current_chunk else sentence
            if self.get_token_length(potential_chunk) <= self.max_tokens:
                current_chunk = potential_chunk
            else:
                if current_chunk:
                    subchunks.append(current_chunk)
                current_chunk = sentence
        
        if current_chunk:
            subchunks.append(current_chunk)
        
        return subchunks

    def process_text_safely(self, text):
        if not text.strip():
            return None

        try:
            subchunks = self.create_subchunks(text)
            all_emotions = []
            
            for subchunk in subchunks:
                if self.get_token_length(subchunk) <= self.max_tokens:
                    emotions = self.classifier(subchunk)
                    if emotions and emotions[0]:
                        all_emotions.append(emotions[0])
            
            if not all_emotions:
                return None

            aggregated_emotions = {}
            for chunk_emotions in all_emotions:
                for emotion in chunk_emotions:
                    label, score = emotion['label'], emotion['score']
                    if label in aggregated_emotions:
                        aggregated_emotions[label].append(score)
                    else:
                        aggregated_emotions[label] = [score]

            averaged_emotions = {
                label: sum(scores) / len(scores)
                for label, scores in aggregated_emotions.items()
            }

            dominant_emotion = max(averaged_emotions.items(), key=lambda x: x[1])
            
            return {
                "emotions": averaged_emotions,
                "dominant_emotion": dominant_emotion[0],
                "confidence": dominant_emotion[1]
            }
        except Exception as e:
            print(f"Error processing text: {str(e)}")
            return None

    def create_dynamic_chunks(self, subtitles, target_token_count=200):
        chunks = []
        current_chunk = {
            "start_time": None,
            "end_time": None,
            "text": "",
            "subtitles": []
        }
        
        for subtitle in subtitles:
            potential_text = current_chunk["text"] + " " + subtitle["text"]
            if self.get_token_length(potential_text) <= target_token_count:
                if current_chunk["start_time"] is None:
                    current_chunk["start_time"] = subtitle["start_time"]
                current_chunk["end_time"] = subtitle["end_time"]
                current_chunk["text"] = potential_text.strip()
                current_chunk["subtitles"].append(subtitle)
            else:
                if current_chunk["text"]:
                    chunks.append(current_chunk)
                current_chunk = {
                    "start_time": subtitle["start_time"],
                    "end_time": subtitle["end_time"],
                    "text": subtitle["text"],
                    "subtitles": [subtitle]
                }
        
        if current_chunk["text"]:
            chunks.append(current_chunk)
        
        return chunks

    def analyze_emotions_in_chunks(self, srt_file, output_json):
        subtitles = self.extract_subtitles_from_srt(srt_file)
        
        if not subtitles:
            print("No subtitles found to analyze.")
            return

        chunks = self.create_dynamic_chunks(subtitles)
        emotion_results = []

        for chunk in chunks:
            result = self.process_text_safely(chunk["text"])
            if result:
                emotion_results.append({
                    "start_time": chunk["start_time"],
                    "end_time": chunk["end_time"],
                    "text": chunk["text"],
                    "emotions": result["emotions"],
                    "dominant_emotion": result["dominant_emotion"],
                    "confidence": result["confidence"]
                })

        try:
            with open(output_json, "w", encoding="utf-8") as json_file:
                json.dump({
                    "timeline": emotion_results,
                    "metadata": {
                        "total_chunks": len(emotion_results),
                        "analyzed_chunks": len(emotion_results)
                    }
                }, json_file, indent=4)
            print(f"Emotion analysis complete. Results saved to {output_json}")
        except Exception as e:
            print(f"Error saving results to JSON: {str(e)}")
