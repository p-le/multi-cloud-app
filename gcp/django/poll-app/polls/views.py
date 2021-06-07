from django.http import HttpResponse, HttpRequest
from django.shortcuts import get_object_or_404, render
from .models import Question


def detail(request: HttpRequest, question_id: int):
    question = get_object_or_404(Question, pk=question_id)
    return render(request, 'polls/detail.html', {'question': question})


def results(request: HttpRequest, question_id: int):
    return HttpResponse(f"You're looking at the results of question {question_id}.")


def vote(request: HttpRequest, question_id: int):
    return HttpResponse(f"You're voting on question {question_id}.")


def index(request: HttpRequest):
    latest_questions = Question.objects.order_by('-pub_date')[:5]
    context = {
        'latest_questions': latest_questions,
    }
    return render(request, 'polls/index.html', context)
